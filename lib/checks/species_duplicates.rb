module Checks
  class SpeciesDuplicates < Check

    def run
      elts = ActiveRecord::Base.connection.execute(<<-SQL
        select s1.id as p1id, s2.id as p2id, s1.scientific_name as p1sci, s2.scientific_name as p2sci, s1.token, s2.token
        FROM species s1
        INNER JOIN species s2 ON s1.token = s2.token
        WHERE s1.id != s2.id
      SQL
                                                  )

      elts.each do |elt|
        good = elt['p1sci'].length > elt['p2sci'].length ? elt['p2sci'] : elt['p1sci']
        bad = elt['p1sci'].length > elt['p2sci'].length ? elt['p1sci'] : elt['p2sci']

        good_sp = Species.find_by_scientific_name(good)
        bad_sp = Species.find_by_scientific_name(bad)

        pp good_sp
        pp bad_sp
        next unless good_sp
        next unless bad_sp

        puts "Keeping #{good_sp.scientific_name}, cleaning #{bad_sp.scientific_name}"
        pl = bad_sp.plant
        bad_sp.destroy
        pl.destroy if pl.reload.species.reload.count == 0
      end

      # length_q = "char_length(scientific_name) - char_length(REPLACE(scientific_name, ' ', ''))"
      # sps = Species.select("id, #{length_q} as levels, scientific_name").where("#{length_q} = 0")
      # sps.each do |sp|
      #   get_or_create_warning_for_record(sp, {
      #     notes: "Specie #{sp.scientific_name} is more likely a genus",
      #     change_type: :deletion
      #   })
      # end
    end

  end
end
