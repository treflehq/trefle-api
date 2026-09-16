# The datasets behind every TRY-sourced value, so the credit CC BY owes them
# can actually be resolved (treflehq/trefle-crawlers#26).
#
# A fact records which datasets contributed to it; this is what turns those
# numbers into people. One row per (dataset, reference) pair rather than per
# dataset: a dataset can cite several publications (dataset 1 cites three).
class CreateTryDatasets < ActiveRecord::Migration[8.0]
  def change
    create_table :try_datasets do |t|
      t.integer :dataset_id, null: false
      t.string :dataset_name
      t.string :contributor
      # Null where TRY's export carries no citable reference — 139 of the 727
      # datasets. Null means "the export has none", never "we did not look":
      # the contributor and dataset name are still recorded so the credit is
      # not simply dropped.
      t.text :reference

      t.timestamps
    end

    add_index :try_datasets, :dataset_id
    add_index :try_datasets, %i[dataset_id reference], unique: true
  end
end
