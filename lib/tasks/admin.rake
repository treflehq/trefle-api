namespace :admin do # rubocop:todo Metrics/BlockLength
  desc 'Maintain completion ratios'
  task maintain_counters: :environment do
    Plant.all.map(&:maintain_metadata!)
  end

  desc 'Find and fix incoherencies'
  task fix_data: :environment do
    count = Plant.where(species_count: 0).count
    puts "Deleting #{count} plants without species"
    Plant.where(species_count: 0).destroy_all
  end

  desc 'Generate siege urls'
  task siege: :environment do # rubocop:todo Metrics/BlockLength
    data = []
    [ # rubocop:todo Metrics/BlockLength
      Kingdom.all,
      Subkingdom.all,
      Division.all,
      DivisionClass.all,
      DivisionOrder.all,
      Family.all,
      Genus.all,
      Plant.last(300),
      Species.last(300)
    ].each do |cl|
      name = cl.first.class.to_s.underscore.pluralize
      clname = cl.first.class
      parameters = []
      controller = "Api::V1::#{cl.first.class.to_s.pluralize}Controller".constantize
      ids = cl.sample(10).map(&:id)
      data << "$(URL)/api/v1/#{name}?token=$(TOKEN)"

      if controller.const_defined?(:FILTERABLE_FIELDS)
        controller::FILTERABLE_FIELDS.each do |f|
          random_filter = (begin
                             clname.where.not(f => nil).last.send(f)
                           rescue StandardError
                             'unknown'
                           end)
          parameters << "filter[#{f}]=#{random_filter}"
        end
      end

      if controller.const_defined?(:ORDERABLE_FIELDS)
        controller::ORDERABLE_FIELDS.each do |f|
          parameters << "order[#{f}]=asc"
          parameters << "order[#{f}]=desc"
        end
      end

      if controller.const_defined?(:RANGEABLE_FIELDS)
        controller::RANGEABLE_FIELDS.each do |f|
          random_range = (begin
                            clname.where.not(f => nil).last.send(f)
                          rescue StandardError
                            'unknown'
                          end)
          other_random_range = (begin
                                  clname.where.not(f => nil).first.send(f)
                                rescue StandardError
                                  'unknown'
                                end)

          parameters << "range[#{f}]=#{random_range}"
          parameters << "range[#{f}]=,#{random_range}"
          parameters << "range[#{f}]=#{other_random_range},#{random_range}"
          parameters << "range[#{f}]=#{random_range},#{other_random_range}"
        end
      end

      parameters << 'q=mama'
      parameters << 'q=coco'
      parameters << 'q=strawberry'
      parameters << 'q=abies'

      data << "$(URL)/api/v1/#{name}?token=$(TOKEN)"

      parameters.each do |p|
        data << "$(URL)/api/v1/#{name}?token=$(TOKEN)&#{p}"
        data << "$(URL)/api/v1/#{name}?token=$(TOKEN)&page=2&#{p}"
      end

      5.times do
        data << "$(URL)/api/v1/#{name}?token=$(TOKEN)&#{parameters.sample(3).join('&')}"
      end

      5.times do
        data << "$(URL)/api/v1/#{name}?token=$(TOKEN)&page=2&#{parameters.sample(3).join('&')}"
      end

      data << "$(URL)/api/v1/#{name}?token=$(TOKEN)&page=2"
      data << "$(URL)/api/v1/#{name}?token=$(TOKEN)&page=3"
      data << "$(URL)/api/v1/#{name}?token=$(TOKEN)&page=4"
      data << "$(URL)/api/v1/#{name}?token=$(TOKEN)&page=5"
      data << "$(URL)/api/v1/#{name}?token=$(TOKEN)&page=9999999"

      ids.each do |id|
        data << "$(URL)/api/v1/#{name}/#{id}?token=$(TOKEN)"
      end
    end
    puts '<><><><><>'
    puts data.join("\n")
    puts '<><><><><>'
    ''
  end

end
