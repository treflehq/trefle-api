class CreateUserQueries < ActiveRecord::Migration[6.0]
  def change
    create_table :user_queries do |t|
      t.references :user, null: false, foreign_key: true
      t.string :controller
      t.string :action
      t.bigint :counter
      t.integer :time

      t.timestamps
    end
  end
end
