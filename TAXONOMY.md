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

## Scope

Trefle indexes vascular plants. Whether hybrids are in or out of that scope is
**not currently settled** — see issue #359. Until it is, their absence from the
dataset should be treated as unmeasured rather than intentional.

## References

- [ICN, Article 26 (autonyms)](https://www.iapt-taxon.org/nomen/pages/main/art_26.html)
- [About WCVP — Kew](https://powo.science.kew.org/about-wcvp)
- [WCVP as a GBIF checklist dataset](https://www.gbif.org/dataset/f382f0ce-323a-4091-bb9f-add557f3a9a2)
