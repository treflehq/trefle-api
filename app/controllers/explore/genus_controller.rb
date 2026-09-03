class Explore::GenusController < Explore::ExploreController
  before_action :set_genus, only: %i[show]

  # GET /genus
  # The genus listing was never implemented (the view referenced
  # variables no action ever set and raised a 500): send visitors to
  # the species exploration instead.
  def index
    redirect_to explore_path
  end

  # GET /genus/1
  # GET /genus/1.json
  def show
    ptitle = @genus.name
    @page_title = ptitle
    @page_description = "#{@genus.name} is a genus of the #{@genus.family&.name} family"
    @page_keywords    = [@genus.name, 'genus', 'plant', 'explore'].compact.join(', ')

    # Picking the best-ranked species regardless of whether it has a photo lets the
    # header fall back to the empty-state placeholder instead of crashing (or silently
    # hiding the genus header) when none of the genus' species has one.
    @species = @genus.species.order(wiki_score: :desc).first
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
