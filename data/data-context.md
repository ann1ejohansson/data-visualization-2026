# Data context: the doorstroomtoets debate, and a codebook for this dataset

This file is for you, the student - it's meant to get you from "I don't know
what any of these Dutch words mean" to "I can read this dataset's column
names and know what's in them" in one read. If you want the fuller story
behind *why* this topic is a live public debate right now (not just what the
words mean), see `doorstroomtoetsen-context.md` in this same folder - this
file is the condensed, practical companion to that one.

You don't need to be Dutch, or know anything about the Dutch education
system, to work with this data. You do need the handful of terms below,
because they show up directly as column names and category labels in the
files `get-data.R` downloads.

## 1. What is a doorstroomtoets?

Dutch primary school runs from **groep 1** to **groep 8** (roughly ages
4-12; "groep" = "group/grade"). Near the end of **groep 8**, every pupil
takes a standardized test called the **doorstroomtoets** ("transfer test" -
*doorstroom* = "flow-through", *toets* = "test"). Its score feeds into the
advice a pupil gets for secondary school.

Since the 2023-2024 school year, a school can choose **which** doorstroomtoets
to use, from six approved providers. That choice turns out not to be neutral
- different providers produce systematically different results, even for
similar pupils - which is the whole reason this dataset is interesting
enough to build a visualization about.

## 2. The Dutch school system, just enough of it

- **Basisonderwijs (BO)** - regular primary school. **Speciaal
  basisonderwijs (SBO)** - special-needs primary school. You'll see both as
  values of the `SOORT_PO` column ("PO" = *primair onderwijs*, primary
  education).
- **Voortgezet onderwijs (VO)** - secondary education, which a pupil enters
  at one of several *tracks* (levels), from most to least practically/most
  to least academically oriented:
  - **PRO** (*praktijkonderwijs*) - practical education, for pupils who need
    the most support
  - **VMBO** (*voorbereidend middelbaar beroepsonderwijs*, "preparatory
    secondary vocational education") - itself split into four
    sub-tracks, practical to more theoretical: **BB** (*basisberoepsgerichte
    leerweg*), **KB** (*kaderberoepsgerichte leerweg*), **GT**
    (*gemengd/theoretische leerweg*)
  - **HAVO** (*hoger algemeen voortgezet onderwijs*) - senior general
    secondary education
  - **VWO** (*voorbereidend wetenschappelijk onderwijs*) - pre-university
    education, the most academic track
  - **VSO** (*voortgezet speciaal onderwijs*) - special-needs secondary
    education
  - Combination labels like `VMBO_GT_HAVO` mean "advice was a toss-up
    between these two tracks" - the school couldn't commit to just one.

Rank order, lowest to highest: PRO < VMBO-BB < VMBO-KB < VMBO-GT < HAVO < VWO.

## 3. The fairness debate, in three sentences

A series of Volkskrant investigations (starting Jan 2025) found that a
pupil's doorstroomtoets result - and therefore their secondary-school advice
- depends measurably on *which of the six providers* their school happened
to pick, even comparing schools serving similarly disadvantaged
populations. Sector bodies (PO-Raad, VO-raad) and a D66 parliamentary motion
pushed back toward a single national test; on 2 July 2026 the responsible
State Secretary announced a plan to consolidate from six providers to one by
school year 2029/2030. Full details, sources, and the specific statistics
behind these claims are in `doorstroomtoetsen-context.md`.

## 4. Glossary

| Dutch | Literal / English | What it means here |
|---|---|---|
| doorstroomtoets | "transfer test" | the standardized groep-8 test this whole dataset is about |
| schoolweging | "school weighting" | a school-level score for how socio-economically disadvantaged its pupil population is (higher = more disadvantaged); see `get-data.R` |
| schooladvies | "school advice" | the secondary-school track a teacher/school recommends for a pupil |
| referentieniveau | "reference level" | a standardized skill level (1F, 1S, 2F - see codebook below) that's meant to mean the same thing regardless of which doorstroomtoets a pupil took |
| groep 8 | "group 8" | the final year of Dutch primary school (~age 11-12) |
| basisonderwijs / PO | "primary education" | regular primary school |
| speciaal basisonderwijs / SBO | "special primary education" | primary school for pupils needing extra support |
| voortgezet onderwijs / VO | "secondary education" | Dutch high school, split into the tracks in section 2 |
| provincie | "province" | the Netherlands has 12; `PROVINCIE` is one of the geographic columns |
| gemeente | "municipality" | more local than a province; `GEMEENTENAAM` |
| instelling / vestiging | "institution" / "location" | a school (`INSTELLING`) can have multiple physical `VESTIGING`en (locations/buildings) |
| leerling(en) | "pupil(s)" | e.g. `aantal_leerlingen` = "number of pupils" |
| gemiddelde | "average" | e.g. `GEM` column suffixes, `gemiddelde_eindscores.txt` |
| aantal | "number/count" | e.g. `AANTAL` column suffixes |
| DUO | *Dienst Uitvoering Onderwijs* | the Dutch government agency that administers and publishes education data (our main data source) |
| CvTE | *College voor Toetsen en Examens* | the body that approves and oversees the six doorstroomtoets providers |
| Onderwijsinspectie | "Education Inspectorate" | evaluates school quality; publishes the schoolweging file |
| CBS | *Centraal Bureau voor de Statistiek* | Dutch national statistics office; calculates schoolweging on the Inspectorate's behalf |

## 5. Codebook

Four files, downloaded by `get-data.R` into `data/raw/`. All four
(`eindscores`, `referentieniveaus`, `schooladviezen`) except `schoolweging`
share the school-identifying columns `INSTELLINGSCODE`/`VESTIGINGSCODE` -
see the join notes at the bottom of `get-data.R` for how `schoolweging`
differs and how to join it in anyway. A `<5` value anywhere means DUO
suppressed a small count for privacy (fewer than 5 pupils) - it is text, not
a number, until you convert it.

### `eindscores_2024-2025.csv`

One row per school. Average raw doorstroomtoets score per provider, for
whichever provider(s) that school actually used.

| Column | English meaning |
|---|---|
| `PEILDATUM_LEERLINGEN` | reference date for the pupil count (1 Oct 2024) |
| `PRIKDATUM` | date this data extract was taken/published |
| `INSTELLINGSCODE` | school code (a.k.a. "BRIN") - the school's main ID |
| `VESTIGINGSCODE` | location code - which physical building, if a school has more than one |
| `INSTELLINGSNAAM_VESTIGING` | school (location) name |
| `POSTCODE_VESTIGING` | postal code |
| `PLAATSNAAM` | town/city |
| `GEMEENTENUMMER` / `GEMEENTENAAM` | municipality code / name |
| `PROVINCIE` | province |
| `SOORT_PO` | school type: `Bo` (regular primary) or `Sbo` (special primary) |
| `DENOMINATIE_VESTIGING` | religious/pedagogical affiliation (e.g. Openbaar = public/non-denominational, Rooms-Katholiek = Roman Catholic, Protestants-Christelijk = Protestant Christian) |
| `BEVOEGD_GEZAG_NUMMER` | school board ("competent authority") ID number |
| `ONTHEFFING_REDEN_ND` | count of pupils exempted from taking any doorstroomtoets |
| `IEP_AANTAL` / `IEP_GEM` | pupils tested / average score, **IEP** provider (Bureau ICE) |
| `ROUTE8_AANTAL` / `ROUTE8_GEM` | pupils tested / average score, **Route 8** provider (A-VISION) |
| `DIA_AANTAL` / `DIA_GEM` | pupils tested / average score, **Dia-Eindtoets** provider (Diataal BV) |
| `AMN_AANTAL` / `AMN_GEM` | pupils tested / average score, **AMN Eindtoets** provider |
| `DOE_AANTAL` / `DOE_GEM` | pupils tested / average score, **DOE** provider - the free, government-funded test (Stichting Cito) |
| `LIB_AANTAL` / `LIB_GEM` | pupils tested / average score, **Leerling in Beeld** provider (Cito B.V.) |

**Important:** raw `_GEM` scores are on six *different, non-comparable*
scales (see `doorstroomtoetsen-context.md` section 7) - you cannot directly
compare, say, `IEP_GEM` to `LIB_GEM`.

### `referentieniveaus_2024-2025.csv`

One row per school. How many pupils reached each standardized reference
level, per subtest. This is the file that makes cross-provider comparison
actually valid, because a reference level is defined the same way regardless
of which doorstroomtoets a pupil took.

Three subtests, each split into three mutually-exclusive achievement
buckets that add up to "how many pupils sat that subtest":

| Column | English meaning |
|---|---|
| `PEILDATUM` | reference date |
| `INSTELLINGSCODE`, `VESTIGINGSCODE`, ... | same identifying/location columns as `eindscores` |
| `REKENEN_LAGER1F` | pupils **below** the basic ("1F") level in **maths** (*rekenen*) |
| `REKENEN_1F` | pupils who reached the basic level, but not the higher one, in maths |
| `REKENEN_1S` | pupils who reached the higher **target** level ("1S") in maths |
| `REKENEN_2F` | (rarely used for maths; its target level is 1S, not 2F - usually 0) |
| `LV_LAGER1F` / `LV_1F` / `LV_2F` | same three buckets, for **reading comprehension** (*leesvaardigheid*, "LV") - target level here is 2F |
| `TV_LAGER1F` / `TV_1F` / `TV_2F` | same three buckets, for **language conventions/writing** (*taalverzorging*, "TV") - target level here is 2F |

"1F" = fundamental/basic level (*fundamenteel niveau*) - what nearly every
pupil should reach. "1S"/"2F" = the higher target level (*streefniveau*) for
maths and language respectively.

### `schooladviezen_2024-2025.csv`

One row per school. How many pupils ended up with each secondary-school
track advice (final advice, including any upward revisions after the test).

| Column | English meaning |
|---|---|
| `PEILDATUM_LEERLINGEN`, `PRIKDATUM`, `INSTELLINGSCODE`, ... | same as `eindscores` |
| `VSO` | advised into special secondary education |
| `PRO` | advised into practical education (*praktijkonderwijs*) |
| `VMBO_B` | advised VMBO, basic vocational track (*basisberoepsgerichte leerweg*) |
| `VMBO_B_K` | advice split between VMBO-basic and VMBO-kader (see below) |
| `VMBO_K` | advised VMBO, "framework" vocational track (*kaderberoepsgerichte leerweg*) |
| `VMBO_K_GT` | advice split between VMBO-kader and VMBO-GT |
| `VMBO_GT` | advised VMBO, mixed/theoretical track (*gemengd/theoretische leerweg*) - the most academic VMBO track |
| `VMBO_GT_HAVO` | advice split between VMBO-GT and HAVO |
| `HAVO` | advised HAVO (senior general secondary) |
| `HAVO_VWO` | advice split between HAVO and VWO |
| `VWO` | advised VWO (pre-university) - the most academic track |
| `ADVIES_NIET_MOGELIJK` | pupils for whom no advice could be determined |

Track order, lowest to highest: `PRO` < `VMBO_B` < `VMBO_K` < `VMBO_GT` <
`HAVO` < `VWO`, with the `_`-joined columns as the in-between "advice was
split across two tracks" categories.

### `schoolweging_2022-2025.ods`

A **workbook**, not a single flat table - it has one sheet per school year
(`"2022-2023"`, `"2023-2024"`, `"2024-2025"`), a three-year-average sheet,
and two explanatory sheets. `get-data.R` reads just the `"2024-2025"` sheet.
One row per school **location** (not per school - see the join note in
`get-data.R`).

| Column | English meaning |
|---|---|
| `OVT` | this sheet's own school-location identifier, formatted like `"00AP\|C1"` - the part before `\|` is the same code as `INSTELLINGSCODE` elsewhere, the part after identifies the location (but NOT the same way `VESTIGINGSCODE` does - see `get-data.R`) |
| `Naam` | school (location) name |
| `BGNR` | school board number (same concept as `BEVOEGD_GEZAG_NUMMER` above) |
| `schoolweging` | the school weighting score itself: higher = more socio-economically disadvantaged pupil population. In practice this dataset's values run roughly 20-40. |
| `aantal_leerlingen` | number of pupils this weighting is based on |
| `spreiding` | "spread" - how much the weighting varies among this school's own pupils (a measure of how mixed the population is, not used in this assignment) |

## Where to go from here

- `doorstroomtoetsen-context.md` - the full research writeup: timeline,
  specific statistics, sources, and a profile of the `eindscores` dataset
- `get-data.R` - downloads all four files above, with more detail in its own
  comments on exactly how they join together (and where that join gets
  tricky)
- `plot-source-code/assignment-1_part-a_copy-this-1.R` /
  `plot-source-code/assignment-1-alternative-dumbbell/` - worked examples
  that actually use this data end to end
