require 'httparty'
require 'colorize'

module Ingester
  class IngesterException < RuntimeError

  end

  class Species

    # Data is a hash like:
    # {
    #   "scientific_name": "Picea abies var. abies",
    #   "rank": "var",
    #   "author": "",
    #   "genus": "Picea",
    #   "status": "accepted",
    #   "confidence": 92
    # }
    def initialize(data, **options)
      @data = data&.deep_symbolize_keys&.compact
      # @data[:scientific_name] = "Mama mia"
      @dry_run = options[:dry_run] || false
      # Explicit source of this ingestion (e.g. 'community' for accepted
      # corrections). Otherwise inferred from the source_* keys of the data.
      @source = options[:source]&.to_s
      @species = ::Species.friendly.find(options[:species_id]) if options[:species_id]

      return unless @data

      check!
      # @TODO perform checks on data here
    end

    def check!
      raise IngesterException, 'No scientific name' if @data[:scientific_name].blank? && @species.nil?
    end

    def ingest!
      return unless @data

      # We get or create the species to change
      @species ||= ::Species.where(scientific_name: @data[:scientific_name]).first
      @species ||= ::Synonym.where(name: @data[:scientific_name]).first&.record

      @species ||= ::Species.new(scientific_name: @data[:scientific_name])

      # If something goes wrong here, we want to go back to the initial state
      # @species.transaction do

      puts "Species for #{@data[:scientific_name]}=#{@species&.scientific_name}"

      override_names!

      # We apply all the data we have on it
      assign_attributes!

      # Source arbitration on trait fields: reject implausible values, keep the
      # column value of a stronger source, and collect provenance facts
      @pending_facts = arbitrate_traits!

      # We update it (or juste return the changes if dry run)
      save_or_return!
      # end
    end

    def override_names!
      return unless @species

      if @data[:scientific_name] != @species&.scientific_name
        @data[:scientific_name] = @species&.scientific_name
        @data[:genus_name] = @species&.genus_name
        @data[:genus_id] = @species&.genus_id
        @data[:rank] = nil
        @data[:author] = nil
        @data[:bibliography] = nil
      end
    end

    def assign_attributes!
      resolve_core_informations!
      resolve_genus!
      resolve_measurements!
      resolve_flags!
      resolve_images!
      resolve_sources!
      resolve_common_names!
      resolve_texts!
      resolve_floats!
      resolve_numbers!
      resolve_bools!
      resolve_enums!
    end

    def save_or_return!
      puts "\nIngesting:".green

      puts @data.to_yaml.green

      puts 'Got: '.green
      puts @species.changes.inspect.green
      puts "\n".green

      if @dry_run

        return return_hash(@species.changes)
      else

        puts '=========== Before save: ==========='
        puts "  changes: #{@species.changes}"

        # binding.pry
        changes = @species.changes
        a = @species.save

        changes = @species.saved_changes unless @species.saved_changes.empty?

        puts '=========== After save: ==========='
        puts "  saved_changes: #{@species.saved_changes}"

        if a
          persist_facts!
          puts '[Ingester] Ingested !'
        else
          puts "[Ingester] Errors while saving: #{@species.errors.full_messages}"
        end
      end

      return_hash(changes)
    end

    # :image_url,
    # :source_gbif,
    # :source_openfarm,
    # :planting_row_spacing_cm,
    # :planting_spread_cm

    # Will resolve scientific_name, author and cie
    def resolve_core_informations!
      {
        scientific_name: @data[:scientific_name],
        rank: @data[:rank],
        year: @data[:year],
        author: @data[:author]
      }.compact.map {|k, v| @species.send("#{k}=", v) }
    end

    # Will try to match genus or create a new one
    def resolve_genus!
      Converter::Genus.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert measurement like fields
    def resolve_measurements!
      Converter::Measurement.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert flags like fields
    def resolve_flags!
      Converter::Flag.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert images
    def resolve_images!
      Converter::Image.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert sources
    def resolve_sources!
      Converter::Source.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert common names
    def resolve_common_names!
      Converter::CommonName.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert text
    def resolve_texts!
      Converter::Text.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert float
    def resolve_floats!
      Converter::Float.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert number
    def resolve_numbers!
      Converter::Number.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert bool
    def resolve_bools!
      Converter::Boolean.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    # Will convert enum
    def resolve_enums!
      Converter::Enum.resolve!(@data).each do |k, v|
        @species.send("#{k}=", v)
      end
    end

    def return_hash(changes = nil)
      {
        id: @species&.id,
        saved: @species&.persisted?,
        changes: changes || @species&.saved_changes,
        valid: @species&.valid?,
        errors: @species&.errors&.full_messages
      }
    end

    # --- Source arbitration & provenance -----------------------------------

    RESERVED_SOURCE_KEYS = %w[id name type reference url].freeze

    # The source of this ingestion: explicit option, else inferred from the
    # source_* keys of the data (strongest one if several), else 'unknown'.
    def detected_source
      return @source if @source.present?

      slugs = @data.keys.map(&:to_s)
        .filter {|k| k.start_with?('source_') }
        .map {|k| k.sub(/\Asource_/, '') }
        .reject {|s| RESERVED_SOURCE_KEYS.include?(s) }
        .map {|s| s.sub(/_[a-z]{2}\z/, '') } # source_wikipedia_en -> wikipedia

      slugs.min_by {|s| Traits.priority_index(s) } || 'unknown'
    end

    # For each changed trait field:
    # - implausible value  -> revert the assignment, fact recorded as :rejected
    # - stronger source already claims this attribute and the column is filled
    #   -> revert the assignment (the claim is still recorded as :active)
    # Returns the facts to persist after a successful save.
    def arbitrate_traits!
      source = detected_source
      facts = []

      @species.changes.slice(*Traits.completion_fields).each do |attr, (old_value, new_value)|
        next if new_value.nil?

        unless Traits.plausible?(attr, new_value)
          @species.send("#{attr}=", old_value)
          facts << { attribute_name: attr, source: source, value: new_value,
                     status: :rejected,
                     notes: "implausible: outside #{Traits.field(attr)['plausible_range']}" }
          next
        end

        unless Traits.allowed_value?(attr, new_value)
          @species.send("#{attr}=", old_value)
          facts << { attribute_name: attr, source: source, value: new_value,
                     status: :rejected,
                     notes: "outside the allowed vocabulary #{Traits.allowed_values(attr).inspect}" }
          next
        end

        if Traits.filled?(attr, old_value) && outranked_for?(attr, source)
          puts "[Ingester][Arbitration] keeping #{attr} (another source claims it at least as strongly, '#{source}' recorded as fact only)"
          @species.send("#{attr}=", old_value)
        end

        facts << { attribute_name: attr, source: source, value: new_value, status: :active }
      end

      facts
    end

    # Only a *strictly stronger* source may overwrite a filled column. On a tie
    # the existing value stays and the newcomer is recorded as a conflicting
    # fact: two sources of equal authority disagreeing must not be settled by
    # crawl order, which is the silent last-write-wins this system exists to
    # remove. Unknown sources all share the lowest rank, so they tie by default.
    # Re-ingesting the *same* source is not affected (handled by superseding).
    def outranked_for?(attr, source)
      return false unless @species.persisted?

      recorded = @species.species_facts.active_status.for_attribute(attr)
      strongest_other = recorded.reject {|f| f.source == source }
        .min_by {|f| Traits.priority_index(f.source) }

      incumbent_rank = if strongest_other
                         Traits.priority_index(strongest_other.source)
                       elsif recorded.any?
                         # Only this source is on record: it owns the value and
                         # may update it (the previous fact is superseded).
                         return false
                       else
                         # Nothing on record at all: the value predates
                         # provenance recording. It is not unclaimed, just
                         # unattributed, so it gets the configured legacy rank
                         # instead of losing by default.
                         Traits.legacy_value_priority_index
                       end

      incumbent_rank <= Traits.priority_index(source)
    end

    def persist_facts!
      (@pending_facts || []).each do |fact|
        ::SpeciesFact.record!(species: @species, **fact)
      end
    rescue StandardError => e
      Rails.logger.warn("[Ingester] Unable to record facts for #{@species&.scientific_name}: #{e.message}")
    end

  end
end
