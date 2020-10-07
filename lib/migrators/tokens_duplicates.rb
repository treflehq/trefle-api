module Migrators
  class TokensDuplicates

    def self.run
      tokens = Species.find_by_sql('select token, count(token) from species group by token HAVING count(token) > 1')
      res = tokens.map do |t|
        species = Species.where(token: t.token).map do |sp|
          res = ::Resolver::Powo.resolve_hash(sp.scientific_name)
          [
            res.nil? || res[:scientific_name] != sp.scientific_name ? false : true,
            sp.id
          ]
        end.to_h
      end

      res.each do |r|
        next if r[true].nil? || r[false].nil?

        good = r[true] && Species.find(r[true])
        duplicate = r[false] && Species.find(r[false])

        next unless good && duplicate

        puts "Merging '#{duplicate.scientific_name}' into '#{good.scientific_name}'"
        good.update_columns(token: "stop-#{SecureRandom.urlsafe_base64(32)}")
        duplicate.update_columns(token: "stop-#{SecureRandom.urlsafe_base64(32)}")
        good.update_columns(rank: :hybrid) if good.scientific_name =~ /×/ && good.species_rank?
        ::Utils::Merger.new([duplicate.id], good.id).merge!
      end
    end

  end
end
