module Checks
  class GenusName < Check

    def run
      pre = @species.scientific_name.split(' ')&.first
      pre = [pre, @species.scientific_name.split(' ')&.second].join(' ') if pre == '×'

      return if pre == @species&.genus&.name

      good_name = [@species&.genus&.name, @species.scientific_name.gsub(pre, '')].compact.flatten.join(' ')

      get_or_create_warning_for_record(
        { notes: "Specie #{@species.scientific_name} genus don't match genus '#{@species&.genus&.name}', expected #{good_name}." },
        { scientific_name: good_name }
      )
    end

  end
end
