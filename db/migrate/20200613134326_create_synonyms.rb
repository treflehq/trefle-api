class CreateSynonyms < ActiveRecord::Migration[6.0]
  def change
    create_table :synonyms do |t|
      t.references :record, polymorphic: true, null: false
      t.string :name
      t.string :author
      t.text :notes

      t.timestamps
    end

    add_reference :foreign_sources_plants, :record, polymorphic: true
  end
end
