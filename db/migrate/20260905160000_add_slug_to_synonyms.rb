class AddSlugToSynonyms < ActiveRecord::Migration[8.0]
  def change
    # Lets a species slug keep resolving after the record is merged into its
    # accepted taxon: the Synonym carries the name, the slug makes it
    # addressable. Backfill: Migrators::SynonymSlugsWorker.
    add_column :synonyms, :slug, :string
    add_index :synonyms, :slug
  end
end
