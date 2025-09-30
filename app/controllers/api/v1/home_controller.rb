class Api::V1::HomeController < ApplicationController

  def index
    # puts request.user_agent
    @plants_count = Rails.cache.fetch('home/plants_count') { Plant.count }
    @detailled_plants_count = Rails.cache.fetch("home/detailled_plants_count-#{@plants_count}") { Species.where.not(foliage_color: nil).count }

    count_per_type = Rails.cache.fetch("home/count_per_type-#{@plants_count}") { Species.group(:rank).count }
    @per_species_plants_count = Rails.cache.fetch("home/per_species_plants_count-#{@plants_count}") do
      {
        'Species' => count_per_type['species'],
        'Varieties' => count_per_type['var'],
        'Hybrids' => count_per_type['hybrid'],
        'Sub-species' => count_per_type['ssp'],
        'Forms' => count_per_type['form'],
        'Cultivars' => count_per_type['cultivar']
      }
    end

    @synonyms_count = Rails.cache.fetch("home/synonyms_count-#{@plants_count}") { Synonym.count }

    render json: {
      plants_count: @plants_count,
      detailled_plants_count: @detailled_plants_count
    }
  end

end
