class AdditionalFieldsForRecordCorrections < ActiveRecord::Migration[6.0]
  def change
    add_column :record_corrections, :source_type, :integer, default: 0, null: false
    add_column :record_corrections, :source_reference, :string
  end
end
