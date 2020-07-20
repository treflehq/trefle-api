# == Schema Information
#
# Table name: record_corrections
#
#  id               :bigint           not null, primary key
#  accepted_by      :integer
#  change_notes     :text
#  change_status    :integer          default("pending"), not null
#  change_type      :integer          default("addition"), not null
#  correction_json  :text
#  notes            :text
#  record_type      :string
#  source_reference :string
#  source_type      :integer          default("external"), not null
#  warning_type     :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  record_id        :bigint
#  user_id          :bigint
#
# Indexes
#
#  index_record_corrections_on_record_type_and_record_id  (record_type,record_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
class RecordCorrection < ApplicationRecord
  belongs_to :record, polymorphic: true, optional: true
  belongs_to :user, optional: true

  scope :status, ->(s) { where(change_status: s) }
  # Ex:- scope :active, -> {where(:active => true)}

  enum change_type: %i[addition update deletion], _suffix: true
  enum change_status: %i[pending accepted rejected], _suffix: true
  enum source_type: %i[external observation report], _suffix: true

  before_validation :set_change_type
  validates_presence_of :source_reference,
                        if: proc {|r| r.external_source_type? },
                        message: 'You need to provide a reference (a link, a publication...) if the correction dont comes from an observation'

  def set_change_type
    self.change_type = (record ? :update : :addition) unless deletion_change_type?
  end

  def self.report!(record:, user:, change_type: :update, notes: nil)
    rc = RecordCorrection.where(
      record: record,
      user: user,
      source_type: :report,
      change_type: change_type
    ).first_or_create!
    rc.update!({
      notes: notes,
      warning_type: :report
    }.compact)
    rc
  end

  def accept!(user_id = nil)
    return unless pending_change_status?
    return unless record_type == 'Species'

    if deletion_change_type?
      record.destroy!
      update(
        accepted_by: user_id,
        change_status: :accepted
      )
    else
      correction = JSON.parse(correction_json)
      i = ::Ingester::Species.new(correction, species_id: record_id)
      res = i.ingest!
      if res[:valid]
        update(
          accepted_by: user_id,
          change_status: :accepted
        )
      else
        update(
          notes: [notes, "Unable to accept, #{res[:errors].join(', ')}"].compact.join("\n")
        )
      end
    end
  end

  # Accept without applying the changes
  def resolve!(user_id = nil)
    update(
      accepted_by: user_id,
      change_status: :accepted,
      notes: [notes, 'Other corrections resolved this correction'].compact.join("\n")
    )
  end

  def reject!
    update(
      change_status: :rejected
    )
  end

end
