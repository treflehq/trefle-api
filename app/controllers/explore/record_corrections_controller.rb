class Explore::RecordCorrectionsController < Explore::ExploreController
  before_action :set_record_correction, only: %i[show]

  # GET /record_correction
  # GET /record_correction.json
  def index
    @page_title       = 'Corrections for plants and species'
    @page_keywords    = 'correction, data, explore, plants, search, species'

    @species = Species.friendly.find(params.require(:species_id))

    @collection ||= RecordCorrection.all
    @collection = @collection.where(record: @species)
    @collection = @collection.where(user_id: current_user.id) if params[:mine]

    @pagy, @collection = pagy(@collection)
  end

  # GET /record_correction/1
  # GET /record_correction/1.json
  def show
    ptitle = @record_correction.scientific_name
    ptitle = "Correction for #{ptitle} (#{@record_correction.common_name})" if @record_correction.common_name
    @page_title       = ptitle
    @page_description = "#{@record_correction.scientific_name} is an #{@record_correction.status} #{@record_correction.rank} of the #{@record_correction.family_name} family"
    @page_keywords    = [@record_correction.scientific_name, @record_correction.common_name, @record_correction.family_name, @record_correction.family_common_name, 'plant', 'explore'].compact.join(', ')

    set_meta_tags(
      image_src: @record_correction.main_image_url,
      og: {
        title:    @record_correction.scientific_name,
        image:    @record_correction.main_image_url,
      }
    )
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_record_correction
    @record_correction = RecordCorrection.find(params[:id])
  end


end
