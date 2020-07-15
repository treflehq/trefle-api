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
class RecordCorrectionSerializer < BaseSerializer
  attributes :record_type, :record_id, :user_id,
             :correction, :warning_type, :change_status,
             :change_type, :accepted_by, :notes, :changes,
             :created_at, :updated_at

  def correction
    JSON.parse(object.correction_json) if object.correction_json
  end

  def changes
    JSON.parse(object.change_notes) if object.change_notes
  end

  # def links
  #   {
  #     self: url_helpers.api_v1_kingdom_path(object)
  #   }
  # end
end
