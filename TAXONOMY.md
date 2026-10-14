# Taxonomic reference

Which source decides what a plant is called, and how names are written.

## WCVP is the authority on accepted names

The **World Checklist of Vascular Plants** (Kew) decides whether a name is
accepted or a synonym, and what the accepted name is. It is the consensus
checklist for vascular plants, built on IPNI's nomenclature, published as a GBIF
checklist dataset and used as the main dataset of the Catalogue of Life.

Everything else is a *data* source, not a taxonomic arbiter:

| Source | Role | Arbitrates names? |
|---|---|---|
| **WCVP** | accepted names, synonymy | **yes** |
| POWO | web front end over WCVP; may lag it slightly | no — defer to WCVP on a disagreement |
| IPNI | nomenclatural: records that a name was *published* | no — it never says what is accepted |
| GBIF | aggregator; its plant backbone follows WCVP | no |
| WFO, Tropicos, USDA, CATMINAT, PlantNet, pfaf… | trait and occurrence data | no |

In the ingester this is `sources.category_priority.core` in
`config/traits.yml`: for author, year, bibliography, rank and status the order
is community, then `powo` (WCVP), IPNI, WFO, GBIF, Tropicos, and a value written before
provenance existed ranks with GBIF: any of the three nomenclatural references
may correct it, an aggregator alone may not. Data from WCVP is ingested under `powo`,
never under `community`: `community` means a human reviewed it.

Two consequences worth stating:

- A disagreement between POWO and WCVP is a lag, not a conflict. WCVP wins.
- **An accepted name is not unique without its author.** Two different taxa can
  carry the same binomial. Any code that treats `scientific_name` as a key is
  making an assumption that will eventually break.

## How names are written

Trefle follows the *International Code of Nomenclature for algae, fungi, and
plants* (ICN). `Utils::ScientificName` implements this.

| Rank | We write | Not |
|---|---|---|
| subspecies | `subsp.` | `ssp.`, `subsp`, `ssp` |
| variety | `var.` | `var` |
| form | `f.` | `fo.`, `fo`, `f` |
| subvariety | `subvar.` | `subvar` |
| hybrid | `×` (U+00D7) | the letter `x` |

`ssp.` is widespread and understood, but `subsp.` is the Code's form, so it is
the one we store. Author citations, publication years and parenthetical author
blocks are stripped from `scientific_name` — the author belongs in its own
column.

## One infraspecific rank per name

The name of an infraspecific taxon is the species name, **one** connecting term
and **one** epithet (ICN Art. 24.1). A string with two of them is not a name:

    Saxifraga aizoon var. aizoon subvar. brevifolia f. multicaulis subf. surculosa

is, in the Code's own example (Art. 24 Ex. 1), the *full classification* of the
subform *Saxifraga aizoon* subf. *surculosa* within its species, "not only its
name". USDA PLANTS prints its infraspecific taxa that way (`Genus species ssp. x
var. y`), and 236 of our records came in with that shape from the December 2022
rebuild, carrying the species' author. IPNI, POWO and WCVP never store such
strings; WFO has a few dozen.

What we do with one:

- The record's name is the trinomial: species, the terminal connecting term,
  the terminal epithet. `Dryas octopetala subsp. octopetala var. kamtschatica`
  is `Dryas octopetala var. kamtschatica`, at rank `var`.
- The author is the author of that name, not of the species or the subspecies.
  An autonym (`… var. octopetala`) has none.
- The longer string is kept as a `Synonym` of the record, so stored slugs and
  external links keep resolving. The position of the variety under its
  subspecies is not stored anywhere else: we are a name index, not a
  classification.
- `ScientificNameStructureValidator` refuses a string with two or more
  connecting terms with its own message, whatever rank the record is filed at.
  The import of 2022 saved them without validation; nothing may again.

The pass that applies this to the 236 records is
`datasets/infraspecific-ranks-2026-10` in `trefle-crawlers`
(`Crawlers::InfraspecificRanks`): merge into the taxon we already hold, or
rename to the trinomial, each record decided against WCVP and WFO.

## Autonyms are not the species

When an infraspecific taxon includes the type of the species, the ICN (Art. 26)
requires its final epithet to repeat the specific epithet unaltered, with no
author citation. That name is the **autonym**, and it is created automatically
the moment any other infraspecific taxon is published under that species.

An autonym is a **narrower circumscription than the species**: the species minus
its other subspecies or varieties.

    Stipa pulcherrima subsp. pulcherrima  ⊂  Stipa pulcherrima

So the two are not interchangeable, and any code that folds one into the other
is making a data decision, not applying a nomenclatural equivalence. The
direction matters:

- Carrying a measurement **from the autonym up to the species** generalises. The
  trait was observed on a subset of the species. Acceptable, with provenance.
- Carrying a measurement **from the species down to the autonym** claims more
  than the source supports. Do not.

Whichever spelling ends up canonical for a record, the other must remain
reachable as a `Synonym`, so stored slugs and external links keep resolving.
`Crawlers::WcvpSynonyms` already works this way: it adds the synonym, never
deletes and never overwrites.

### Two shapes that look wrong and are not

- **Section aggregates.** In apomictic genera WCVP accepts a few names at
  species rank that are written as a section: the common dandelion is
  *Taraxacum* sect. *Taraxacum*, and *Taraxacum officinale* is its synonym.
  `Genus sect. Name` is therefore a valid species-rank name.
- **One-letter epithets.** *Lepanthes o* is a published, accepted orchid.

## Scope

Trefle covers the plant kingdom, not only vascular plants. Each group needs a
reference that arbitrates its names:

- **Vascular plants** (flowering plants, conifers, ferns, lycophytes): WCVP,
  as above.
- **Bryophytes** (mosses, liverworts, hornworts): WCVP does not cover them.
  WFO will arbitrate them once they are reconciled against it (statuses,
  authors, a place in the hierarchy). Until then they are **hidden**
  (`species.hidden_reason = 'bryophyte'`): kept in the database with
  everything attached, resolvable by slug, but out of the lists, the search
  and the counts. The 2022 import brought ~35,000 of them with no arbiter, and
  WFO treats about half of the names served as accepted as synonyms.
- **Fossils** (extinct taxa, known from the Paleobiology Database through
  GBIF) are out of scope: an empty record is deleted, one carrying data is
  hidden (`hidden_reason = 'fossil'`).

Whether hybrids are in or out of scope is **not currently settled** — see
issue #359. Until it is, their absence from the dataset should be treated as
unmeasured rather than intentional.

## References

- [ICN, Article 24 (names of infraspecific taxa; Ex. 1 on full classification)](https://www.iapt-taxon.org/nomen/pages/main/art_24.html)
- [ICN, Article 26 (autonyms)](https://www.iapt-taxon.org/nomen/pages/main/art_26.html)
- [About WCVP — Kew](https://powo.science.kew.org/about-wcvp)
- [WCVP as a GBIF checklist dataset](https://www.gbif.org/dataset/f382f0ce-323a-4091-bb9f-add557f3a9a2)
