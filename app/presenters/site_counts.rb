# The two headline figures the public site quotes for the size of the dataset
# (#437): how many taxa the species table holds (species, subspecies,
# varieties, hybrids and forms together) and how many plants, i.e. main
# species, they group under. Every page that states a size reads it from
# here, so the home hero, the About page and the API home agree with each
# other and with the database instead of each carrying its own figure.
#
# Both are full-table counts over ~500k rows, so they are cached for a day.
# Nothing on the site needs them fresher than that.
class SiteCounts

  CACHE_EXPIRY = 1.day

  def self.species_count
    Rails.cache.fetch('site_counts/v1/species', expires_in: CACHE_EXPIRY) { Species.count }
  end

  def self.plants_count
    Rails.cache.fetch('site_counts/v1/plants', expires_in: CACHE_EXPIRY) { Plant.count }
  end

  # Rounded to the nearest thousand for running text ("about 499,000"), so a
  # figure quoted in prose never pretends to be exact and never visibly drifts
  # from a count cached at a different time. Small counts (a test database)
  # are returned as they are.
  def self.approximate(count)
    return count if count < 10_000

    (count / 1000.0).round * 1000
  end

end
