# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

puts "Seeding database..."
require_relative './botanic_seeds'

SpeciesDistribution.counter_culture_fix_counts
Species.counter_culture_fix_counts
ForeignSourcesPlant.counter_culture_fix_counts
Synonym.counter_culture_fix_counts
SpeciesImage.counter_culture_fix_counts

u = User.where(email: 'guest@trefle.io').first_or_create!(
  password: SecureRandom.urlsafe_base64(32),
  admin: false,
  name: 'Guest',
  organization_name: 'Trefle',
  organization_url: 'https://trefle.io'
)
u.confirm

