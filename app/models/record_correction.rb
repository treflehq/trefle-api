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
    return accept_check!(user_id) if warning_type&.starts_with?('Checks::')

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

  # If the correction if from a check, we delegate this to the check
  def accept_check!(user_id = nil)
    check = warning_type.constantize.new(record_id)
    check.accept!(user_id)
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

  def update_scientific_name_references(new_scientific_name = nil)
    new_scientific_name ||= record.scientific_name

    if change_notes
      notes = JSON.parse(change_notes)
      notes['scientific_name'] = new_scientific_name if notes['scientific_name']
      self.change_notes = notes.to_json
    end

    if correction_json
      correction = JSON.parse(correction_json)
      correction['scientific_name'] = new_scientific_name if correction['scientific_name']
      self.correction_json = correction.to_json
    end
    save
  end

end
