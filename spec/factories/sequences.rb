FactoryBot.define do
  # Scientific name validators only accept letters and hyphens,
  # so sequences must not embed digits.
  sequence(:latin_epithet) {|n| "testum#{('a'..'z').to_a[n % 26]}#{('a'..'z').to_a[(n / 26) % 26]}" }
  sequence(:latin_genus) {|n| "Genustest#{('a'..'z').to_a[n % 26]}#{('a'..'z').to_a[(n / 26) % 26]}" }
end
