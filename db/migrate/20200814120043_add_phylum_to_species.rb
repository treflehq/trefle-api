class AddPhylumToSpecies < ActiveRecord::Migration[6.0]
  def change
    add_column :species, :phylum, :string
    add_column :species, :wiki_score, :integer
  end
end
