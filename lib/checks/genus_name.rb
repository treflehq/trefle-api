module Checks
  # The first word of a species name and its genus record disagree. One of
  # the two is wrong, and the check has to decide which before proposing
  # anything (#418):
  #
  #   - a genus of that name exists: the species is well named and hangs
  #     under the wrong genus (a homonym, a typo at import). Propose the
  #     re-link, the ingester resolves `genus` to the record.
  #   - no genus of that name exists: the name is the suspect. Propose the
  #     spelling the genus record gives, as before.
  #
  # On the 2026-10-10 dump, 107 of 167 pending rename proposals would have
  # turned a name Kew or WFO accepts into one nobody knows.
  class GenusName < Check

    def run
      pre = @species.scientific_name.split(' ')&.first
      pre = [pre, @species.scientific_name.split(' ')&.second].join(' ') if pre == '×'
      genus_word = pre.delete_prefix('× ')

      return if pre == @species&.genus&.name || genus_word == @species&.genus&.name

      if ::Genus.exists?(name: genus_word)
        return get_or_create_warning_for_record(
          { notes: "Species #{@species.scientific_name} is linked to genus '#{@species&.genus&.name}' but its name says " \
                   "'#{genus_word}', a genus we hold. Expected a re-link to #{genus_word}." },
          { genus: genus_word }
        )
      end

      good_name = [@species&.genus&.name, @species.scientific_name.gsub(pre, '')].compact.flatten.join(' ').squish

      get_or_create_warning_for_record(
        { notes: "Specie #{@species.scientific_name} genus don't match genus '#{@species&.genus&.name}', expected #{good_name}." },
        { scientific_name: good_name }
      )
    end

  end
end
