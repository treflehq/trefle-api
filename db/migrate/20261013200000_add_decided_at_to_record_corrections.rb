# When a correction was accepted or rejected. The activity counters read
# `updated_at`, which any later edit of the row moves (a notes line, a
# re-pointed record), so a decision taken in March could count as this
# week's. Rows decided before this column existed take their last update as
# the best date available.
class AddDecidedAtToRecordCorrections < ActiveRecord::Migration[8.1]
  def up
    add_column :record_corrections, :decided_at, :datetime
    add_index :record_corrections, :decided_at
    execute 'UPDATE record_corrections SET decided_at = updated_at WHERE change_status <> 0'
  end

  def down
    remove_index :record_corrections, :decided_at
    remove_column :record_corrections, :decided_at
  end
end
