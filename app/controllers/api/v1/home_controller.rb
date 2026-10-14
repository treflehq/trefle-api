class Api::V1::HomeController < ApplicationController

  def index
    @plants_count = SiteCounts.plants_count
    @detailed_plants_count = Rails.cache.fetch("home/detailled_plants_count-#{@plants_count}") { Species.where.not(foliage_color: nil).count }

    count_per_type = Rails.cache.fetch("home/count_per_type-#{@plants_count}") { Species.group(:rank).count }
    @per_species_plants_count = Rails.cache.fetch("home/per_species_plants_count-#{@plants_count}") do
      {
        'Species' => count_per_type['species'],
        'Varieties' => count_per_type['var'],
        'Hybrids' => count_per_type['hybrid'],
        'Sub-species' => count_per_type['ssp'],
        'Forms' => count_per_type['form'],
        'Subvarieties' => count_per_type['subvar']
      }
    end

    @synonyms_count = Rails.cache.fetch("home/synonyms_count-#{@plants_count}") { Synonym.count }

    dataset = DatasetVersion.current
    response.headers['X-Trefle-Data-Version'] = dataset.version if dataset

    render json: {
      plants_count: @plants_count,
      detailed_plants_count: @detailed_plants_count,
      # Deprecated misspelling, kept so existing clients keep reading it.
      detailled_plants_count: @detailed_plants_count,
      dataset_version: dataset&.version,
      dataset: dataset_block(dataset)
    }
  end

  private

  # What a researcher needs to cite the data they are reading: the version,
  # when it was released, the licence, and where the citation and the
  # history of versions live.
  def dataset_block(dataset)
    {
      version: dataset&.version,
      released_at: dataset&.released_at,
      licence: CitationHelper::LICENCE[:name],
      licence_url: CitationHelper::LICENCE[:url],
      citation_url: citation_url,
      changelog_url: api_v1_changelog_url
    }
  end

end
