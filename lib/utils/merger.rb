module Utils
  class Merger

    class MergerException < RuntimeError

    end

    def initialize(species_ids, good_species_id = nil)
      @species = species_ids.map {|s| Species.friendly.find(s) }
      @good_species = good_species_id ? Species.friendly.find(good_species_id) : resolve_good_species
      @to_delete = Species.where(id: @species.map(&:id)).where.not(id: @good_species.id)
    end

    def merge!
      @to_delete.each do |elt|
        merge_a_into_b(elt, @good_species)
      end
    end

    def to_sentence
      "Merging #{@to_delete.pluck(:scientific_name, :slug).map {|e| e.join('#') }.join(', ')} into [#{@good_species.scientific_name}##{@good_species.slug}]"
    end

    def merge_a_into_b(a_to_delete, b_to_keep)
      puts "Merging #{a_to_delete.scientific_name}##{a_to_delete.slug} into #{b_to_keep.scientific_name}##{b_to_keep.slug}"

      b_to_keep.transaction do
        migrate_species_images!(a_to_delete.species_images, b_to_keep)
        migrate_foreign_sources_plants!(a_to_delete.foreign_sources_plants, b_to_keep)
        migrate_record_corrections!(a_to_delete.record_corrections, b_to_keep)
        migrate_synonyms!(a_to_delete.synonyms, b_to_keep)
        migrate_common_names!(a_to_delete.common_names, b_to_keep)
        migrate_species_distributions!(a_to_delete.species_distributions, b_to_keep)
        migrate_trends!(a_to_delete.species_trends, b_to_keep)

        final_attributes = a_to_delete.merge_attributes.merge(b_to_keep.merge_attributes)
        
        # Dont cycle main id
        # final_attributes = ['main_species_id'] = nil # if final_attributes['main_species_id'] == b_to_keep.reload.id
        
        puts ">> Ready to merge:"
        puts final_attributes.inspect
        puts "into #{b_to_keep.inspect}"

        b_to_keep.update(main_species_id: nil) if b_to_keep.has_root_name? && b_to_keep.species_rank?
        
        b_to_keep.reload.update!(final_attributes)
        a_to_delete.delete
      end
      puts "Merged #{a_to_delete.scientific_name}##{a_to_delete.slug} into #{b_to_keep.scientific_name}##{b_to_keep.slug} !"
    end

    def migrate_species_images!(species_images, b_to_keep)
      species_images.each do |spi|
        if SpeciesImage.where(species_id: b_to_keep.id, image_url: spi.image_url).any?
          spi.destroy
        else
          spi.update(species_id: b_to_keep.id)
        end
      end
    end

    def migrate_foreign_sources_plants!(foreign_sources_plants, b_to_keep)
      foreign_sources_plants.each do |fsp|
        if ForeignSourcesPlant.where(record: b_to_keep, fid: fsp.fid).any?
          fsp.destroy
        else
          fsp.update(record: b_to_keep, species_id: b_to_keep.id)
        end
      end
    end

    def migrate_record_corrections!(record_corrections, b_to_keep)
      record_corrections.each do |rc|
        if RecordCorrection.where(record: b_to_keep, change_notes: rc.change_notes).any?
          rc.destroy
        else
          rc.update(record: b_to_keep, notes: rc.notes + "\nMerged into a new species")
        end
      end
    end

    def migrate_synonyms!(synonyms, b_to_keep)
      synonyms.each do |syn|
        if Synonym.where(record: b_to_keep, name: syn.name).any?
          syn.destroy
        else
          syn.update(record: b_to_keep)
          # migrate_foreign_sources_plants!(syn.foreign_sources_plants, b_to_keep)
        end
      end
    end

    def migrate_common_names!(common_names, b_to_keep)
      common_names.each do |cname|
        if CommonName.where(record: b_to_keep, name: cname.name).any?
          cname.destroy
        else
          cname.update(record: b_to_keep)
        end
      end
    end

    def migrate_species_distributions!(species_distributions, b_to_keep)
      species_distributions.each do |sdis|
        if SpeciesDistribution.where(species_id: b_to_keep.id, zone_id: sdis.zone_id).any?
          sdis.destroy
        else
          sdis.update(species_id: b_to_keep.id)
        end
      end
    end

    def migrate_trends!(trends, b_to_keep)
      trends.delete_all
    end

    def resolve_good_species
      tokens = @species.map(&:token).uniq
      raise MergerException, "Can't select the good species to merge, species have several tokens: #{tokens}" if tokens.length > 1

      token = tokens.first
      good_info = Resolver.best_resolve(token)
      raise MergerException, "Can't select the good species to merge, no results on GBIF" unless good_info

      good_species = Species.find_by_scientific_name(good_info[:scientific_name])
      raise MergerException, "Can't select the good species to merge, unable to find species #{good_info[:scientific_name]} in our database" unless good_species

      good_species
    end
  end
end
