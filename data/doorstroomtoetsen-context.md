# Context: the doorstroomtoets fairness debate

Research notes compiled 2026-09-17 to give background on the Dutch "doorstroomtoets" (primary-school transfer/placement test) fairness debate, tied to the dataset `data/gemiddelde_eindscores.txt`. Compiled from web research (see Sources); not exhaustive, and the debate is ongoing, so treat later developments as updates to check for.

## 1. What is a doorstroomtoets?

- Every group-8 (final primary-school year) pupil in the Netherlands takes a **doorstroomtoets** ("transfer test"), a standardized test in Dutch/reading and maths whose main purpose is to inform the secondary-school (voortgezet onderwijs, VO) level advice a pupil receives (vmbo/havo/vwo tracks, etc.).
- It replaced the older **eindtoets** ("final test", incl. the well-known Citotoets) from the 2023-2024 school year onward, under a legal reform. Key change versus the old system: the test now happens **earlier in the year (~February)**, before/alongside the definitive school advice, rather than as a late second opinion after advice was already given.
- Since 2023-2024, schools may choose **which** doorstroomtoets to administer, from a set of ministry-approved providers — this school choice is the crux of the fairness debate.
- A school's test result can lead to a **"heroverweging"** (reconsideration) of the teacher's original school advice — in principle only upward.

## 2. The providers (matches the columns in `gemiddelde_eindscores.txt`)

Six approved providers, exactly matching the `*_AANTAL`/`*_GEM` column pairs in the dataset:

| Column prefix | Provider | Publisher | Notes |
|---|---|---|---|
| `LIB` | Leerling in Beeld | Cito B.V. (commercial) | Successor product line to the old Citotoets |
| `IEP` | IEP Eindtoets | Bureau ICE | |
| `ROUTE8` | Route 8 | A-VISION | Digital, adaptive |
| `AMN` | AMN Eindtoets | AMN B.V. | |
| `DOE` | DOE (Overheidsdoorstroomtoets) | **Stichting Cito** (nonprofit, distinct from Cito B.V.) | The free, government-funded test — successor to the old Centrale Eindtoets; digital and adaptive; the only one with dedicated versions for pupils with language-development disorders or visual impairment |
| `DIA` | Dia-Eindtoets | Diataal BV | |

A school reports counts (`*_AANTAL`) and average scores (`*_GEM`) only for the provider(s) it actually used — hence most rows in the dataset have five of the six provider columns at `0`. Counts under 5 are suppressed as `"<5"` (privacy rule), which shows up as `NA` in the average-score field.

## 3. The core fairness/comparability problem

Despite a shared **"ankerset"/equating system** run by the College voor Toetsen en Examens (CvTE) meant to make the six tests statistically comparable, independent analyses keep finding **large, persistent differences by provider**:

- **Reference-level attainment differs sharply.** E.g. reading: AMN ~88.5% of pupils reach the 1F level vs. ~99.2% on paper LIB; at the higher 2F level, Route 8 ~48.8% vs. paper LIB ~79.8%. Maths: 1S level, paper LIB ~48.5% vs. Route 8 ~25.3% — roughly double.
- **School-advice distributions differ even more starkly.** AMN pupils received a pro/vmbo-bb (lowest track) recommendation ~18x more often than paper-LIB pupils (14.6% vs 0.8%); conversely paper LIB gave vwo advice to ~15.4% of pupils vs. AMN's 4.4%.
- **This is not fully explained by school population.** A Volkskrant analysis specifically compared schools with *equal* "schoolweging" (a standard socio-economic-disadvantage weighting used in Dutch education policy) and still found schools using paper LIB scored structurally higher than comparable schools using Route 8 — i.e. the gap is a property of the test/provider, not (only) of who takes it.
- **Digital vs. paper format matters too.** CvTE's own analysis: 77% of pupils with a VWO teacher-advice get a VWO test-advice on the *paper* LIB test, vs. only 43% on the *digital* IEP test.
- Independent psychometricians consulted by the Volkskrant concluded **"je kunt niet vaststellen dat de doorstroomtoetsen vergelijkbaar zijn"** ("you cannot establish that the transfer tests are comparable") — test form/length differences undermine reliability, and their shared conclusion was that only a single, common test would truly optimize comparability.

## 4. The Volkskrant reporting specifically

- **~25 Jan 2025** — First major Volkskrant investigation. Framing: the doorstroomtoets was designed to *increase* equal opportunity (an objective check on teacher bias) but, per their reporting, is doing the opposite. Triggered partly by a Rotterdam secondary school's bridge-class coordinator reporting a record number of high-track enrollments, many of whom then struggled and had to be moved down (e.g. to mavo 2), with knock-on effects on pupils' confidence. Consulted: testing experts, CvTE, PO-Raad, Ministry of OCW.
- **Follow-up analysis (schoolweging-controlled, journalist Den Breejen)** — the piece that directly compares providers *within* equal schoolweging bands and finds the gap survives; widely picked up as the doorstroomtoets being an **"ongelijkheidsmachine"** ("inequality machine"). Conclusion: test choice affects both individual pupils' advice *and* how the Inspectorate evaluates schools, which the reporting calls unsustainable.
- **2026 results round-up** — reported gaps between providers have narrowed somewhat versus 2025, but the residual problem is framed sharply: **"an identical level of skill can lead to divergent test recommendations."** Schools serving more disadvantaged populations (higher schoolweging) adjust/override advice more often than average-weighting schools; regional differences in secondary-school supply and parental expectations are also cited as confounders. PO-Raad's response: still "no proof" the test increases equal opportunity, and it may be *widening* gaps tied to educational disadvantage; PO-Raad also wants test results decoupled from Inspectorate school-quality judgements and favors delaying track selection to age 14-15.

## 5. Policy response / where things stand (as of mid-2026)

- Sector bodies (**PO-Raad**, **VO-raad**, Ouders & Onderwijs) have been pushing for **one single doorstroomtoets** rather than six competing ones.
- A **D66 motion (Ilana Rooderkerk)** in the Tweede Kamer pushed the government to investigate consolidating to one test; CvTE was tasked with exploring this.
- **2 July 2026** — State Secretary **Judith Tielen** announced the cabinet's intent to move from **6 providers to 1 single national doorstroomtoets**, target: **school year 2029/2030** (both digital and paper versions of the one test). Her stated reasoning:
  - "Volledige vergelijkbaarheid is een utopie" (full comparability across different tests is a utopia) — every variation in test design shifts results.
  - A single test removes doubt about equivalence → more genuinely equal educational opportunity.
  - The test format itself is framed as a partial corrective to underestimation of certain groups (e.g. girls) in teacher-only advice — so the goal isn't to scrap testing, but to fix comparability.
  - Consolidation is meant to increase public/professional trust in the system.
- Ministry survey of schools found a **paradox**: most schools agree in principle that there should be one test, but each wants to keep *its own* current provider — logically impossible if the field consolidates to one.
- Next steps flagged: continued consultation with schools/testing experts through 2029/2030, exploring how to assess practical/vocational skills, reconsidering the format of school advice itself, reviewing whether test results should factor into Inspectorate school-quality evaluations, and provisions for pupils needing accommodations.

## 6. Relevance / caveats for working with `data/gemiddelde_eindscores.txt`

- This file looks like a DUO/OCW open-data extract at the **school (vestiging) level**, one row per school, with `PEILDATUM_LEERLINGEN = 20241001` and `PRIKDATUM = 20250904` — i.e. it's a 2024-2025 school-year snapshot released ~Sept 2025, contemporaneous with the schoolweging-controlled Volkskrant analysis described above.
- It has the **average score per provider per school**, but **no schoolweging column** — to reproduce anything like the Volkskrant's "equal schoolweging, different provider" comparison, schoolweging would need to be joined in from a separate DUO dataset (school-level schoolweging is published separately, keyed by `INSTELLINGSCODE`/`VESTIGINGSCODE` or BRIN).
- Small-count privacy suppression (`"<5"` → the paired `_GEM` field is `NA`) will bias any naive average calculated across schools — needs explicit handling (e.g. exclude or flag suppressed rows), not silent NA-drop-and-forget, if this feeds a "which provider scores higher" visualization.
- Because schools *self-select* their provider, any raw between-provider comparison in this file conflates **(a)** genuine test-difficulty/scoring differences and **(b)** compositional differences in which schools chose which test — exactly the confound the Volkskrant controlled for via schoolweging. Worth flagging explicitly in any assignment/analysis using this data.

## 7. Dataset exploration (`gemiddelde_eindscores.txt`, run 2026-09-17)

Full profiling done in R (`readr`/`dplyr`); numbers below are computed, not estimated.

**Shape:** 6,324 rows (one per school/vestiging) × 26 columns. No exact duplicate rows; `INSTELLINGSCODE`+`VESTIGINGSCODE` is a unique key. Single snapshot: `PEILDATUM_LEERLINGEN` = 20241001, `PRIKDATUM` = 20250904 for every row (2024-25 school year, pupil-count reference date 1 Oct 2024, data pulled 4 Sept 2025).

**Columns:** identifiers/metadata (`INSTELLINGSCODE`, `VESTIGINGSCODE`, name, postcode, plaats, gemeente, provincie), school type (`SOORT_PO`: 95.9% "Bo" regular primary, 4.1% "Sbo" special primary), denomination (`DENOMINATIE_VESTIGING`, 19 categories), board number, an exemption-count field (`ONTHEFFING_REDEN_ND`), then six `{PROVIDER}_AANTAL`/`{PROVIDER}_GEM` pairs for IEP, ROUTE8, DIA, AMN, DOE, LIB.

**Data-quality quirk:** all six `*_AANTAL` columns are stored as **character**, not numeric, because small counts are privacy-suppressed as the literal string `"<5"` — reading them naively as numeric silently produces `NA`/errors. Must be parsed explicitly (numeric + a separate suppression flag).

**Missingness:** only the `*_GEM` columns have NAs, and only where the paired `*_AANTAL` is `"<5"` (suppressed) — e.g. `LIB_GEM` 1.72% NA (109 rows), `IEP_GEM` 1.71% (108), `ROUTE8_GEM` 0.87%, `DIA_GEM` 0.60%, `AMN_GEM` 0.11%, `DOE_GEM` 0.06%. All other columns are 100% populated.

**Provider market share** (schools with a usable score, i.e. count > 5; suppressed `<5` schools shown separately):

| provider | schools (n>5) | schools suppressed (<5) | % of all schools using it | mean school-avg score | score SD | raw score range |
|---|---|---|---|---|---|---|
| LIB | 2,838 | 109 | 46.6% | 176.5 | 6.9 | 154–189 |
| IEP | 2,452 | 108 | 40.5% | 78.2 | 5.7 | 53.4–89.8 |
| ROUTE8 | 483 | 55 | 8.5% | 195.8 | 24.9 | 109–262 |
| DIA | 327 | 38 | 5.8% | 358.6 | 6.2 | 332–374 |
| AMN | 94 | 7 | 1.6% | 407.9 | 24.1 | 316–456 |
| DOE | 33 | 4 | 0.6% | 296.5 | 26.8 | 222–344 |

LIB and IEP together cover ~87% of schools; the free government test (DOE) is used by well under 1% of schools despite being the "default"/no-cost option. **Raw `_GEM` scores are on six completely different, non-overlapping numeric scales** (e.g. IEP ~53-90 vs. AMN ~316-456) — they cannot be compared or averaged across providers without a conversion to a shared metric (e.g. 1F/1S/2F reference levels, which this file does **not** contain). This is the same comparability problem the Volkskrant reporting centers on, just visible directly in the raw numbers.

**Provider choice is not random — it clusters by region and denomination**, which is exactly the self-selection confound flagged in §6:
- *By province* (share of single-provider schools): IEP is the plurality choice in Friesland (67.6%) and Zeeland (61.8%), while LIB dominates in Gelderland (59.5%) and Utrecht (59.4%). ROUTE8 is disproportionately used in Limburg (25.4% vs. ~7% national average elsewhere).
- *By denomination*: IEP is the plurality choice for "Algemeen bijzonder" schools (48.1%) and roughly ties LIB for Protestants-Christelijk/Openbaar; LIB is the plurality for Rooms-Katholiek schools (49.4%).

**Multi-provider schools are rare:** 6,089 schools (96.3%) use exactly one provider, 222 use two, 5 use three, and 8 schools report no usable pupils for any provider (likely too-small or non-reporting schools). So almost every school's "which test" is effectively a fixed categorical trait, not a within-school comparison.

**Special education:** Sbo (special primary) schools score lower than Bo schools on every single provider (e.g. IEP: Bo mean 78.2 vs Sbo mean 58.9; AMN: Bo 422 vs Sbo 337), consistent with the population Sbo serves — a reminder that `SOORT_PO` should be controlled for (or segmented) in any cross-school comparison.

**Volume:** ~167,943 pupils total with a known (non-suppressed) score across all schools/providers; median school reports 23 pupils with a usable score, up to 130 at the largest school (RK Basisschool De Oostwijzer, Zoetermeer). 795 distinct school boards (`BEVOEGD_GEZAG_NUMMER`).

## Sources

- [Onderzoek Volkskrant benadrukt noodzaak van één doorstroomtoets — PO-Raad](https://www.poraad.nl/onderwijskwaliteit/overgang-po-vo/onderzoek-volkskrant-benadrukt-noodzaak-van-een-doorstroomtoets)
- [Doorstroomtoets vergroot kansenongelijkheid — VOS/ABB](https://www.vosabb.nl/doorstroomtoets-vergroot-kansenongelijkheid-po-vo/)
- [Doorstroomtoets is 'ongelijkheidsmachine' — VOS/ABB](https://www.vosabb.nl/doorstroomtoets-is-ongelijkheidsmachine-po-vo/)
- [Gelijkheid blijft uit: doorstroomtoets 2026 toont hardnekkige verschillen — Nationale Onderwijsgids](https://www.nationaleonderwijsgids.nl/basisonderwijs/gelijkheid-blijft-uit-doorstroomtoets-2026-toont-hardnekkige-verschillen/)
- [Discussies doorstroomtoets (5): verschillen tussen toetsaanbieders — Wij-leren.nl](https://wij-leren.nl/discussies-doorstroomtoets-deel-5.php)
- [Discussies doorstroomtoets (3): Objectieve graadmeter of versterker van ongelijkheid? — Wij-leren.nl](https://wij-leren.nl/discussies-doorstroomtoets-deel-3.php)
- [Onderzoek naar doorstroomtoetsen — Tweede Kamer](https://www.tweedekamer.nl/kamerstukken/plenaire_verslagen/kamer_in_het_kort/onderzoek-naar-doorstroomtoetsen)
- [Kabinet wil in 2030 terug naar één doorstroomtoets — PO-Raad](https://www.poraad.nl/onderwijskwaliteit/overgang-po-vo/kabinet-wil-in-2030-terug-naar-een-doorstroomtoets)
- [Kamer wil snel één doorstroomtoets — VO-raad](https://www.vo-raad.nl/nieuws/kamer-wil-snel-een-doorstroomtoets)
- [Staatssecretaris wil van 6 naar 1 doorstroomtoets — Rijksoverheid.nl](https://www.rijksoverheid.nl/actueel/nieuws/2026/07/02/staatssecretaris-wil-van-zes-naar-een-doorstroomtoets)
- [Doorstroomtoets in het basisonderwijs — OCW in cijfers](https://www.ocwincijfers.nl/sectoren/primair-onderwijs/leerlingen/prestaties-eindtoets)
- [Overheidsdoorstroomtoets DOE — Cito](https://cito.nl/centrale-toetsen-en-examens/toetsen-po/overheidsdoorstroomtoets-doe/)
- [Verschillen doorstroomtoets — Cito](https://cito.nl/de-doorstroomtoets-helpt-om-door-te-stromen/verschillen-doorstroomtoets/)
