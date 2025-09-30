namespace :dump do # rubocop:todo Metrics/BlockLength
  desc 'Create seeds from dev database'
  task generate: :environment do # rubocop:todo Metrics/BlockLength

    div = Division.all
    dcl = DivisionClass.where(division_id: div.pluck(:id))
    dor = DivisionOrder.where(division_class_id: dcl.pluck(:id))
    family_base = Family.where(division_order_id: dor.pluck(:id))
    genus_base = Genus.where(family_id: family_base.pluck(:id))

    species_base_ids = [
      Species.friendly.find('abies-alba').id,
      Species.where.not(ligneous_type: nil).where(genus_id: genus_base.pluck(:id)).sample.id,
      SpeciesDistribution.joins(:species).where(species: { genus_id: genus_base.pluck(:id) }).sample.id,
      Species.where(genus_id: genus_base.pluck(:id), complete_data: true).sample.id,
      Species.where(genus_id: genus_base.pluck(:id), complete_data: false, status: :accepted).sample.id,
      Species.where(genus_id: genus_base.pluck(:id)).where(synonyms_count: (0...200)).sample.id
    ]

    species_base = Species.where(id: species_base_ids)
    complete_plant_id = Plant.where(completion_ratio: (60...100)).sample&.id
    plants = Plant.where(id: [*species_base.pluck(:plant_id), complete_plant_id].compact)
    species_ids = plants.map(&:species_ids).flatten
    synonym_ids = Species.where(id: species_ids).map(&:synonym_ids).flatten
    fsources = ForeignSourcesPlant.where(record_type: 'Species', record_id: species_ids)
    genus = genus_base.where(id: plants.pluck(:genus_id))
    family = family_base.where(id: genus.pluck(:family_id), division_order_id: dor.pluck(:id))

    File.write('db/botanic_seeds.rb', '')
    [
      Zone,
      ForeignSource,
      Kingdom,
      Subkingdom,
      div,
      dcl,
      dor,
      family,
      genus,
      plants,
      Species.where(id: species_ids),
      Synonym.where(id: synonym_ids),
      CommonName.where(record_type: 'Species', record_id: species_ids),
      SpeciesDistribution.where(species_id: species_ids),
      SpeciesImage.where(species_id: species_ids),
      fsources
    ].each do |elt|
      SeedDump.dump(
        elt,
        file: 'db/botanic_seeds.rb',
        append: true,
        exclude: %i[slug inserted_at updated_at created_at]
      )
    end

  end

end
