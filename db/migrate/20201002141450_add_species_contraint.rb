class AddSpeciesContraint < ActiveRecord::Migration[6.0]
  
  def up
    elts = ActiveRecord::Base.connection.execute(<<-SQL
        ALTER TABLE species ADD CONSTRAINT CHK_main_species CHECK (main_species_id != id);
      SQL
    )
  end

  def down
    elts = ActiveRecord::Base.connection.execute(<<-SQL
        ALTER TABLE species DROP CONSTRAINT CHK_main_species
      SQL
    )
  end
end
