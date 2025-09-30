require 'httparty'
require 'colorize'

module Resolver
  class ResolverException < RuntimeError

  end

  def self.resolve_species(species_id)
    species = Species.friendly.find(species_id)

    {
      gbif: try_resolves(Gbif, species),
      powo: try_resolves(Powo, species)
    }
  end

  def self.try_resolves(resolver, species)
    data = resolver.resolve_hash(species.scientific_name)
    data ||= resolver.resolve_hash(species.token)
    data
  end

  def self.best_resolve(scientific_name)
    [
      Resolver::Gbif.resolve_hash(scientific_name) || {},
      Resolver::Powo.resolve_hash(scientific_name) || {}
    ].reduce(&:merge)
  end
end
