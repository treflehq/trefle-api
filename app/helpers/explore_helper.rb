# Browse chrome for the explore pages: filter chips and rank labels.
module ExploreHelper
  RANK_LABELS = {
    'species' => 'Species',
    'ssp' => 'Subspecies',
    'var' => 'Variety',
    'form' => 'Form',
    'hybrid' => 'Hybrid',
    'subvar' => 'Subvariety'
  }.freeze

  def rank_chip_label(rank)
    RANK_LABELS.fetch(rank, rank.humanize)
  end

  HIDDEN_NOTICES = {
    'bryophyte' => 'This moss, liverwort or hornwort is kept out of the lists and the search: no reference arbitrates ' \
                   'their names in Trefle yet, so its name and status may be out of date.',
    'fossil' => 'This is an extinct taxon, known from fossils only. It is kept out of the lists and the search.'
  }.freeze

  # Why a hidden record (Species::HIDDEN_REASONS) is not in the lists.
  def hidden_species_notice(species)
    HIDDEN_NOTICES.fetch(species.hidden_reason, 'This record is kept out of the lists and the search.')
  end

  # "L., 1753": the authorship and year of the name, as it is cited after the
  # binomial. Either may be missing; nil when both are.
  def species_authorship(species)
    [species.author.presence, species.year.presence].compact.join(', ').presence
  end

  # A filter chip is a plain GET link that toggles one query parameter while
  # keeping the others (search included) and resetting the page.
  def explore_chip(label, key, value, active: false)
    kept = request.query_parameters.except('page')
    target = active ? kept.except(key.to_s) : kept.merge(key.to_s => value)
    link_to label,
            explore_path(target.symbolize_keys),
            class: class_names('explore-chip', 'explore-chip--active' => active),
            aria: { pressed: active.to_s }
  end
end
