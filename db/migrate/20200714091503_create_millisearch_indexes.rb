class CreateMillisearchIndexes < ActiveRecord::Migration[6.0]
  def up
    Search.instance.with do |client|
      index = client.get_or_create_index('species', primaryKey: 'id')
    end
  end

  def down
    Search.instance.with{|e| e.delete_index('species') }
  end
end
