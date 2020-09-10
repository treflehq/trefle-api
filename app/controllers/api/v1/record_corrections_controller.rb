class Api::V1::RecordCorrectionsController < Api::ApiController
  before_action :set_record, only: %i[create report update destroy]

  FILTERABLE_FIELDS = %w[
    user_id
    record_id
    record_type
    warning_type
    change_status
    change_type
    accepted_by
    source_type
    external
  ].freeze

  ORDERABLE_FIELDS = %w[
    user_id
    record_id
    record_type
    warning_type
    change_status
    change_type
    accepted_by
    source_type
    external
  ].freeze

  def index
    @collection = collection
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

  def collection
    return @collection if @collection

    @collection ||= RecordCorrection.all
    @collection = @collection.where(record: Species.friendly.find(params[:species_id])) if params[:species_id]
    @collection = @collection.where(user_id: current_user.id) if params[:mine]

    # @collection = @collection.preload(:plant, :genus, :synonyms)

    @collection = apply_filters(@collection, FILTERABLE_FIELDS)
    @collection = apply_sort(@collection, ORDERABLE_FIELDS, default_sort: { updated_at: :desc })

    @pagy, @collection = pagy(@collection)
    @collection
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
