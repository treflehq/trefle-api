class CreateDataRuns < ActiveRecord::Migration[8.0]
  def change
    # Durable journal of the data operations that shape the dataset —
    # imports, purges, migrations, crawls — wherever they run from: the
    # sidekiq pods and one-off runs against the production database (e.g.
    # through a port-forward) all write here, so the trace survives pod log
    # rotation and lives next to the data it changed.
    create_table :data_runs do |t|
      t.string :runnable, null: false
      t.string :kind, null: false
      t.jsonb :arguments, default: {}, null: false
      t.boolean :dry_run, default: false, null: false
      t.integer :status, default: 0, null: false
      t.jsonb :report, default: {}, null: false
      t.jsonb :impact, default: {}, null: false
      t.string :host
      t.string :revision
      t.text :error
      t.datetime :started_at, null: false
      t.datetime :finished_at

      t.timestamps
    end

    add_index :data_runs, :started_at
    add_index :data_runs, %i[runnable started_at]
  end
end
