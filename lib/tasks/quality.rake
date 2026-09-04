# Data quality measurement (see config/traits.yml).
#
#   rake quality:snapshot             # write dated quality rows (trend tracking)
#   rake quality:priorities           # most requested species with poor data
#   rake quality:recompute_completion # refresh completion_ratio on all species
namespace :quality do

  desc 'Write data quality snapshot rows for today (global, per field, per rank, per source)'
  task snapshot: :environment do
    result = Quality::Snapshot.run!

    puts "Snapshot #{result[:date]}: #{result[:species_count]} species, #{result[:fields_count]} fields"
    DataQualitySnapshot.on(result[:date]).global.where.not(attribute_name: nil)
      .sort_by {|s| s.fill_rate || 0 }.each do |s|
      puts format('  %-32<name>s %6.1<fill>f%% filled  %6<implausible>d implausible  %6<conflicts>d conflicts',
                  name: s.attribute_name, fill: s.fill_rate || 0,
                  implausible: s.implausible_count, conflicts: s.conflict_count)
    end
  end

  desc 'Most requested species with the poorest data — the work queue'
  task priorities: :environment do
    rows = Quality::Priorities.fetch(limit: (ENV['LIMIT'] || 100).to_i)

    next puts('No demand data (species_trends, wiki_score and gbif_score are all empty).') if rows.empty?

    line = '%-8<id>s %-40<name>s %-12<completion>s %<demand>s'
    puts "(demand signal: #{rows.first.signal})"
    puts format(line, id: 'id', name: 'scientific_name', completion: 'completion', demand: 'demand')
    rows.each do |r|
      puts format(line, id: r.id, name: r.scientific_name,
                        completion: "#{r.completion_ratio || 0}%", demand: r.demand)
    end
  end

  desc 'Recompute completion_ratio/complete_data for every species and plant (no callbacks)'
  task recompute_completion: :environment do
    Migrators::CompletionWorker.new.perform
    puts 'Done (details in the Rails log)'
  end

end
