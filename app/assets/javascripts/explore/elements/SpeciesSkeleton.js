import React from 'react'

// Shown by SpeciesPage while the species payload (specifications, growth,
// images, distribution, synonyms) is still loading, so the content column
// doesn't collapse to a bare "Loading..." string on an otherwise empty page
// (see issue #239).
const SpeciesSkeleton = () => (
  <div className="species-skeleton" aria-busy="true" aria-live="polite">
    <span className="is-sr-only">Loading species data…</span>
    {[0, 1, 2].map(section => (
      <section className="section content" key={section}>
        <div className="skeleton-line skeleton-line--title" />
        <div className="skeleton-line" />
        <div className="skeleton-line" />
        <div className="skeleton-line skeleton-line--short" />
      </section>
    ))}
  </div>
)

export default SpeciesSkeleton
