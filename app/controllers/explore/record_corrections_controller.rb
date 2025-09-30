class Explore::RecordCorrectionsController < Explore::ExploreController
  before_action :set_record_correction, only: %i[show]
  has_scope :status, allow_blank: false

  # GET /record_correction
  # GET /record_correction.json
  def index
    @page_title       = 'Corrections for plants and species'
    @page_keywords    = 'correction, data, explore, plants, search, species'

    p = params.permit(:search, order: {})

    @species = Species.friendly.find(params.require(:species_id)) if params[:species_id]

    @collection ||= apply_scopes(RecordCorrection.all)
    @collection = @collection.where(record: @species) if @species
    @collection = @collection.where(user_id: current_user.id) if params[:mine]
    @collection = @collection.order(p.to_h.dig('order')) if p[:order]

    @pagy, @collection = pagy(@collection)
  end

  # GET /record_correction/1
  # GET /record_correction/1.json
  def show
    @species = @record_correction.record

    ptitle = "Correction for #{@species.scientific_name}"
    @page_title = ptitle
    @page_description = "#{@species.scientific_name} is an #{@species.status} #{@species.rank} of the #{@species.family_name} family"
    @page_keywords    = [@species.scientific_name, @species.common_name, @species.family_name, @species.family_common_name, 'plant', 'explore'].compact.join(', ')

    set_meta_tags(
      image_src: @species.main_image_url,
      og: {
        title: @species.scientific_name,
        image: @species.main_image_url
      }
    )
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_record_correction
    @record_correction = RecordCorrection.find(params[:id])
  end

end
