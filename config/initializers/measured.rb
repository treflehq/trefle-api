Measured::Area = Measured.build do
  unit :mm2, value: '0.01 cm2', aliases: %i[square_millimeter square_millimeters square_millimetre square_millimetres]
  unit :cm2, value: '0.0001 m2', aliases: %i[square_centimeter square_centimeters square_centimetre square_centimetres]
  unit :m2,  aliases: %i[square_meter square_meters square_metre square_metres]
  unit :km2, value: '1000000 m2', aliases: %i[square_kilometer square_kilometers square_kilometre square_kilometres]
  unit :mi2, value: '2.58999 km2',  aliases: %i[square_mile square_miles]
  unit :yd2, value: '0.836127970373 m2', aliases: %i[square_yard square_yards]
  unit :ft2, value: '0.092903 m2',  aliases: %i[square_foot square_feet]
  unit :in2, value: '6.4516 cm2', aliases: %i[square_inch square_inches]
  unit :ha, value: '10000 m2', aliases: %i[hectare hectares]
  unit :ac, value: '4046.86 m2', aliases: %i[acre acres]
end
