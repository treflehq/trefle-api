class Explore::GenusController < Explore::ExploreController
  before_action :set_genus, only: %i[show]

  # GET /genus
  # GET /genus.json
  def index
    # search = params[:search]
    # @page_title = 'Explore plants and genus'
    # @page_keywords = 'explore, plants, search, genus'

    # if search.blank?
    #   @collection ||= Species.all.preload(:plant, :genus, :synonyms).order(wiki_score: :desc)
    #   @pagy, @collection = pagy(@collection)
    # else
    #   options = {
    #     includes: %i[synonyms genus plant],
    #     boost_by: [:gbif_score],
    #     fields: ['common_name^10', 'common_names^8', 'scientific_name^5', 'synonyms^3', 'author', 'genus', 'family', 'family_common_name', 'distributions']
    #   }.compact

    #   @collection = Species.pagy_search(search, **options)
    #   @pagy, @collection = pagy_searchkick(@collection, items: (params[:limit] || 20).to_i)
    # end
  end

  # GET /genus/1
  # GET /genus/1.json
  def show
    ptitle = @genus.name
    @page_title = ptitle
    @page_description = "#{@genus.name} is a genus of the #{@genus.family&.name} family"
    @page_keywords    = [@genus.name, 'genus', 'plant', 'explore'].compact.join(', ')

    @species = @genus.species.where.not(main_image_url: nil).order(wiki_score: :desc).first
    set_meta_tags(
      image_src: @species&.main_image_url,
      og: {
        title: @genus.name,
        image: @species&.main_image_url
      }
    )
    @collection = @genus.species.order(wiki_score: :desc)
    @pagy, @collection = pagy(@collection)
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_genus
    @genus = Genus.friendly.find(params[:id])
  end

end
