# Dataset size in running text, from SiteCounts (#437).
module SiteCountsHelper
  # "454,000": the approximate number of plants, delimited.
  def site_plants_figure
    approximate_count(SiteCounts.plants_count)
  end

  # "499,000": the approximate number of taxa in the species table, delimited.
  def site_species_figure
    approximate_count(SiteCounts.species_count)
  end

  def approximate_count(count)
    number_with_delimiter(SiteCounts.approximate(count))
  end
end
