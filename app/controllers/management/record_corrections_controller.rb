class Management::RecordCorrectionsController < Management::ManagementController

  before_action :set_record_correction, only: %i[destroy accept reject]

  has_scope :status, allow_blank: false

  PER_PAGE = [50, 100, 200].freeze

  # GET /management/record_corrections
  # The review queue: filtered by status and check type, newest first.
  def index
    p = params.permit(:warning_type, order: {})

    scope = apply_scopes(RecordCorrection.all)
    @status_counts = RecordCorrection.group(:change_status).count
    @warning_type_counts = scope.group(:warning_type).count
      .each_with_object(Hash.new(0)) {|(type, n), acc| acc[type.presence] += n }
      .sort_by {|_, n| -n }
    scope = scope.where(warning_type: p[:warning_type].presence || [nil, '']) if p.key?(:warning_type)
    scope = p[:order] ? scope.order(p.to_h['order']) : scope.order(id: :desc)

    @per_page = PER_PAGE.include?(params[:per].to_i) ? params[:per].to_i : PER_PAGE.first
    @pagy, @record_corrections = pagy(scope.preload(:record, :user), items: @per_page)
  end

  # PATCH /management/record_corrections/bulk
  # Accepts or rejects the selected corrections one by one.
  def bulk
    ids = Array(params[:ids]).map(&:to_i)
    decision = params[:decision].to_s
    return redirect_to(return_path, alert: 'Select at least one correction.') if ids.empty? || %w[accept reject].exclude?(decision)

    selected = RecordCorrection.pending_change_status.where(id: ids)
    # A deletion destroys the record: it is accepted one by one, never in bulk.
    skipped = decision == 'accept' ? selected.deletion_change_type.count : 0
    selected = selected.where.not(change_type: :deletion) if decision == 'accept'
    results = selected.map {|rc| decide(rc, decision) }
    done = results.count(true)
    message = "#{done} correction(s) #{decision}ed."
    message += " #{results.size - done} could not be and stay pending, with the reason in their notes." if done < results.size
    message += " #{skipped} deletion(s) skipped, accept them one by one." if skipped.positive?
    redirect_to return_path, notice: message
  end

  def accept
    respond_to do |format|
      if decide(@record_correction, 'accept')
        format.html { redirect_to return_path, notice: "Correction ##{@record_correction.id} accepted." }
        format.json { head :no_content }
      else
        reason = @record_correction.notes.to_s.lines.last.to_s.strip
        format.html { redirect_to return_path, alert: "Correction ##{@record_correction.id} could not be accepted. #{reason}" }
        format.json { render json: { error: reason }, status: :unprocessable_entity }
      end
    end
  end

  def reject
    respond_to do |format|
      if decide(@record_correction, 'reject')
        format.html { redirect_to return_path, notice: "Correction ##{@record_correction.id} rejected." }
        format.json { head :no_content }
      else
        format.html { redirect_to return_path, alert: "Correction ##{@record_correction.id} could not be rejected." }
        format.json { head :unprocessable_entity }
      end
    end
  end

  # DELETE /management/record_corrections/1
  def destroy
    @record_correction.destroy
    respond_to do |format|
      format.html { redirect_to return_path, notice: "Correction ##{@record_correction.id} deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_record_correction
    @record_correction = RecordCorrection.find(params[:id])
  end

  # accept!/reject! leave a refused correction pending (accept! appends the
  # reason to its notes) rather than raising: the outcome is read back from
  # the status, so a refusal is never reported as a success.
  def decide(correction, decision)
    decision == 'accept' ? correction.accept!(current_user.id) : correction.reject!
    correction.reload
    decision == 'accept' ? correction.accepted_change_status? : correction.rejected_change_status?
  end

  # Back to the filtered page the decision was taken from (same filters,
  # same page), never outside the review queue.
  def return_path
    back = params[:return_to].to_s
    return back if back.start_with?(management_record_corrections_path) && !back.start_with?('//')

    management_record_corrections_path(status: :pending)
  end
end
