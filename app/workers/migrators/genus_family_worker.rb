# Fills the family of genera that have none, from a genus -> family mapping
# (World Checklist of Vascular Plants, Kew).
#
# 484 genera carried no family, which broke the taxonomic chain for every
# species under them. Mostly ferns, lycophytes and bryophytes — groups heavily
# reclassified in the last two decades.
#
# Only fills gaps: a genus that already has a family is never touched, so this
# cannot silently rewrite existing taxonomy. Replayable.
#
#   Migrators::GenusFamilyWorker.perform_async
#   Migrators::GenusFamilyWorker.new.perform('/path/to/mapping.csv')
class Migrators::GenusFamilyWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migrations, retry: false, backtrace: true

  DEFAULT_MAPPING = 'datasets/wcvp-genus-family.csv'.freeze

  def perform(mapping_path = nil, dry_run = false) # rubocop:disable Style/OptionalBooleanParameter
    path = Rails.root.join(mapping_path || DEFAULT_MAPPING)
    unless File.exist?(path)
      Rails.logger.error("[GenusFamilyWorker] mapping not found: #{path}")
      return false
    end

    mapping = load_mapping(path)
    report = { linked: 0, family_created: 0, unmatched: [], already_set: 0 }

    Genus.where(family_id: nil).find_each do |genus|
      family_name = mapping[genus.name]
      if family_name.blank?
        report[:unmatched] << genus.name
        next
      end

      family = Family.find_by(name: family_name)
      if family.nil?
        family = Family.create!(name: family_name)
        report[:family_created] += 1
      end

      genus.update!(family_id: family.id) unless dry_run
      report[:linked] += 1
    end

    log_report(report, dry_run)
    report
  end

  private

  def load_mapping(path)
    File.readlines(path).each_with_object({}) do |line, memo|
      genus, family = line.strip.split(',', 2)
      next if genus.blank? || family.blank?

      memo[genus] = family
    end
  end

  def log_report(report, dry_run)
    Rails.logger.info(
      "[GenusFamilyWorker]#{' DRY RUN' if dry_run} linked=#{report[:linked]} " \
      "families_created=#{report[:family_created]} unmatched=#{report[:unmatched].size}"
    )
    return if report[:unmatched].empty?

    # Genera absent from the mapping are expected: WCVP covers vascular plants
    # only, so bryophyte genera (Pottia, Aneura, Kurzia...) will not be found.
    Rails.logger.info("[GenusFamilyWorker] unmatched sample: #{report[:unmatched].first(20).join(', ')}")
  end
end
