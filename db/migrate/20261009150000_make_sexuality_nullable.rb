class MakeSexualityNullable < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  # sexuality was NOT NULL DEFAULT 0, so all 464,186 production species read
  # as "documented" while none of them was (#385, the #351 pattern). It now
  # carries an enum numbered from 1: 0 has no meaning left, and undocumented
  # is NULL like every other trait column.
  #
  # Dropping the default and the constraint is metadata only. The 0 -> NULL
  # rewrite goes in batches outside a transaction, so it never holds one long
  # lock on the species table while the canary and production share it.
  def up
    change_column_default :species, :sexuality, from: 0, to: nil
    change_column_null :species, :sexuality, true

    loop do
      updated = execute(<<~SQL.squish).cmd_tuples
        UPDATE species SET sexuality = NULL
        WHERE id IN (SELECT id FROM species WHERE sexuality = 0 LIMIT 20000)
      SQL
      break if updated.zero?
    end
  end

  def down
    execute 'UPDATE species SET sexuality = 0 WHERE sexuality IS NULL'
    change_column_null :species, :sexuality, false
    change_column_default :species, :sexuality, from: nil, to: 0
  end
end
