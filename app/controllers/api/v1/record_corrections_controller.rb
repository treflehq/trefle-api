class Api::V1::RecordCorrectionsController < Api::ApiController
  before_action :set_record, only: %i[create report update destroy]

  def index
    @collection = RecordCorrection.all
    @collection = @collection.order(created_at: :asc)
    @pagy, @collection = pagy(@collection)

    links = collection_links(@collection, name: :record_corrections)

    render_serialized_collection(
      @collection,
      RecordCorrectionSerializer,
      links: links
    )
  end

  def show
    @resource = RecordCorrection.find(params[:id])

    render_serialized_resource(
      @resource,
      RecordCorrectionSerializer,
      meta: resource_metadata(@resource)
    )
  end

  # Create a correction
  def create
    pp @record
    submission = SubmitCorrection.call(
      record: @record,
      user: current_user,
      correction: params[:correction]&.to_unsafe_hash,
      notes: params[:notes],
      change_type: params[:change_type],
      source_type: params[:source_type],
      source_reference: params[:source_reference]
    )

    if submission.success?
      render_serialized_resource(
        submission.record_correction,
        RecordCorrectionSerializer,
        meta: resource_metadata(submission.record_correction)
      )
    else
      render_error(submission.messages, :unprocessable_entity)
    end
  end

  protected

  def set_record
    @record = set_record_species || set_record_poly
  end

  def set_record_species
    return unless params[:species_id]

    Species.friendly.find(params[:species_id])
  end

  def set_record_poly
    return unless params[:record_type] && params[:record_id]

    record_class = (begin
                      params[:record_type]&.classify&.constantize
                    rescue StandardError
                      nil
                    end)

    record_class&.friendly&.find(params[:record_id])
  end

  def record_correction_params
    params.permit(
      :notes,
      :change_type,
      :source_type,
      :source_reference
    )
  end

end