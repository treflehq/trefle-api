require 'rspec/expectations'

RSpec.shared_examples 'a rangeable collection' do |klass, ranges|

  ranges.each do |range|
    it "and can be ranged by #{range}" do
      sample_value = klass.where.not(range => nil)&.first&.send(range) || klass&.first&.send(range)
      sample_value_bis = klass.where.not(range => nil)&.last&.send(range) || klass&.last&.send(range)
      elts = klass.send("range_by_#{range}".to_sym, *[sample_value, sample_value_bis].sort)
      pp elts.pluck(range)
      puts "Testing ranging on #{range} = #{[sample_value, sample_value_bis].sort} (#{elts} - #{elts&.count})"
      get :index, params: params.merge(range: { range => [sample_value, sample_value_bis].sort.join(',') })
      puts "elts => #{elts.to_sql}"
      puts "assigns => #{assigns(:collection).to_sql}"
      expect(assigns(:collection).to_sql).to match(/"[a-z_]*"."#{range}" >= /)
      expect(assigns(:collection).to_sql).to match(/ AND "[a-z_]*"."#{range}" < /)
    end
  end
end

RSpec.shared_examples 'a searchable collection' do |klass|

  # it 'and can be searched' do
  #   elts = klass.search('a')
  #   get :index, params: params.merge(q: 'a')
  #   puts "elts => #{elts.to_sql}"
  #   puts "assigns => #{assigns(:collection).to_sql}"
  #   expect(assigns(:collection).to_sql).to match(/LIKE '%?a%?'/)
  # end
end

RSpec.shared_examples 'a filterable collection' do |klass, filters|

  filters.each do |filter|
    it "and can be filtered by #{filter}" do
      next unless klass.last.respond_to?(filter)

      sample_value = klass.where.not(filter => nil)&.first&.send(filter) || klass&.first&.send(filter)
      elts = klass.send("filter_by_#{filter}".to_sym, sample_value)
      # pp elts.pluck(filter)
      # puts "Testing filtering on #{filter} = #{sample_value} (#{elts} - #{elts&.count})"
      get :index, params: params.merge(filter: { filter => sample_value })
      # puts assigns(:collection).to_sql
      expect(assigns(:collection).to_sql).to match(filter)
    end
  end
end

RSpec.shared_examples 'a filterable_not collection' do |klass, filters_not|

  filters_not.without('image_url').each do |filter|
    it "and can be filter_not_by #{filter}" do
      sample_value = klass.where.not(filter => nil)&.first&.send(filter) || klass&.first&.send(filter)
      elts = klass.send("filter_not_by_#{filter}".to_sym, 'null')
      # pp elts.pluck(filter)
      # puts "Testing filtering on #{filter} = #{sample_value} (#{elts} - #{elts&.count})"
      get :index, params: params.merge(filter_not: { filter => nil })
      # puts assigns(:collection).to_sql
      expect(assigns(:collection).to_sql).to match(filter)
      expect(assigns(:collection).to_sql).to match(/NOT/)
    end
  end
end

RSpec.shared_examples 'an orderable collection' do |klass, orders|

  orders.each do |order|
    it "and can be ordered DESC by #{order}" do
      elts = klass.sort_with(order => 'desc')
      get :index, params: params.merge(order: { order => 'desc' })
      # puts "elts => #{elts.to_sql}"
      # puts "assigns => #{assigns(:collection).to_sql}"
      expect(assigns(:collection).to_sql).to match(/ORDER BY "[a-z_]*"\."#{order}" DESC/)
      expect(assigns(:collection).first).to eq(elts.first)
    end

    it "and can be ordered ASC by #{order}" do
      elts = klass.sort_with(order => 'asc')
      get :index, params: params.merge(order: { order => 'asc' })
      # puts "elts => #{elts.to_sql}"
      # puts "assigns => #{assigns(:collection).to_sql}"
      expect(assigns(:collection).to_sql).to match(/ORDER BY "[a-z_]*"\."#{order}" ASC/)
      expect(assigns(:collection).first&.id).to eq(elts.first&.id)
    end
  end
end
