# codebook.R
#
# One row per variable: the raw columns of each source file, then the
# variables the dashboard derives from them. `gap` names the kind of
# data-reality gap to watch for (selection, missing, recording, derivation,
# consistency) and says why, in one or two sentences.
#
# kind decides how the codebook summarises the column:
#   const   - same value in every row
#   id      - identifier / free text: count distinct values
#   cat     - categorical: frequency bars
#   count   - pupil count stored as text, may contain "<5"
#   score   - decimal-comma average score (0 when the provider wasn't used)
#   num     - plain numeric (schoolweging file)
#   derived - computed in derive_vars(); follows the "<5" setting

library(tibble)

prov_rows <- function(p, who) {
  tribble(
    ~var, ~file, ~kind, ~label, ~description, ~gap,
    paste0(p, "_AANTAL"), "eindscores", "count",
    paste0("Pupils tested with ", p),
    paste0("Number of group-8 pupils at this school who took the ", who, ". \"0\" means the school did not use this provider; \"<5\" means 1-4 pupils (suppressed for privacy)."),
    "Recording: stored as text because of \"<5\". Reading it with as.numeric() silently turns every suppressed count into NA.",
    paste0(p, "_GEM"), "eindscores", "score",
    paste0("Average raw ", p, " score"),
    paste0("School average on the ", who, " scale. Only meaningful for schools that used this provider; 0 otherwise, and NA when the count is \"<5\"."),
    "Consistency: each provider has its own scale, so this column can only be compared with the same column at other schools, never with another provider's _GEM."
  )
}

CODEBOOK <- bind_rows(
  tribble(
    ~var, ~file, ~kind, ~label, ~description, ~gap,
    "PEILDATUM_LEERLINGEN", "eindscores", "const", "Pupil reference date", "Date on which pupils were counted: 1 October 2024 (school year 2024-25).", "Consistency: schoolweging is also available as a three-year average; make sure you know which year you are comparing against.",
    "PRIKDATUM", "eindscores", "const", "Extract date", "Date DUO took this extract (4 September 2025).", "",
    "INSTELLINGSCODE", "eindscores", "id", "School code (BRIN)", "The school's four-character ID. Together with VESTIGINGSCODE it uniquely identifies a row.", "Selection: the join key to the other files. The schoolweging file uses it inside a combined code (OVT).",
    "VESTIGINGSCODE", "eindscores", "cat", "Location code", "Which building of the school. \"00\" for the main (often only) location.", "Consistency: the schoolweging file numbers locations differently (C1, C2...), so locations can't be matched by code.",
    "INSTELLINGSNAAM_VESTIGING", "eindscores", "id", "School name", "Name of the school location.", "",
    "POSTCODE_VESTIGING", "eindscores", "id", "Postcode", "Postcode of the location. The first four digits (PC4) are matched to coordinates for the map.", "Derivation: PC4 centroids place a school roughly, not exactly.",
    "PLAATSNAAM", "eindscores", "id", "Town", "Town or city.", "",
    "GEMEENTENAAM", "eindscores", "id", "Municipality", "Municipality name (GEMEENTENUMMER is its code).", "",
    "PROVINCIE", "eindscores", "cat", "Province", "One of the 12 Dutch provinces.", "Selection: providers cluster by region (Route 8 in Limburg, IEP in Friesland), so province is a confounder.",
    "SOORT_PO", "eindscores", "cat", "School type", "Bo = regular primary school; Sbo = special primary school for pupils who need extra support.", "Selection: Sbo schools serve a different population and have no schoolweging, so they drop out of every schoolweging comparison.",
    "DENOMINATIE_VESTIGING", "eindscores", "cat", "Denomination", "Religious or pedagogical affiliation (Openbaar = public, Rooms-Katholiek = Roman Catholic, ...).", "Selection: provider choice differs by denomination too.",
    "BEVOEGD_GEZAG_NUMMER", "eindscores", "id", "School board number", "The board that runs the school. Boards often choose one test for all their schools.", "Selection: schools within a board aren't independent choices.",
    "ONTHEFFING_REDEN_ND", "eindscores", "count", "Pupils exempted", "Pupils exempted from taking any doorstroomtoets.", "Selection: exempted pupils aren't in any score, percentage or advice-by-test figure."
  ),
  bind_rows(Map(prov_rows, PROVIDERS, PROVIDER_NAMES[PROVIDERS])),
  tribble(
    ~var, ~file, ~kind, ~label, ~description, ~gap,
    "REKENEN_LAGER1F", "referentieniveaus", "count", "Maths: below 1F", "Pupils below the basic (fundamental) maths level 1F.", "Recording: \"<5\" is very common here, because most schools have only a handful of pupils in this bucket.",
    "REKENEN_1F", "referentieniveaus", "count", "Maths: 1F, not 1S", "Pupils who reached basic level 1F but not the target level 1S.", "",
    "REKENEN_1S", "referentieniveaus", "count", "Maths: 1S", "Pupils who reached the maths target level 1S.", "",
    "REKENEN_2F", "referentieniveaus", "count", "Maths: 2F", "Not used for maths (always 0 in this file): the maths target level is 1S.", "Recording: an all-zero column. Check before you build anything on it.",
    "LV_LAGER1F", "referentieniveaus", "count", "Reading: below 1F", "Pupils below basic reading level 1F (LV = leesvaardigheid).", "",
    "LV_1F", "referentieniveaus", "count", "Reading: 1F, not 2F", "Pupils at basic reading level but not the target level 2F.", "",
    "LV_2F", "referentieniveaus", "count", "Reading: 2F", "Pupils who reached the reading target level 2F.", "",
    "TV_LAGER1F", "referentieniveaus", "count", "Language conventions: below 1F", "Pupils below 1F in language conventions / spelling (TV = taalverzorging).", "",
    "TV_1F", "referentieniveaus", "count", "Language conventions: 1F, not 2F", "Pupils at 1F but not 2F in language conventions.", "",
    "TV_2F", "referentieniveaus", "count", "Language conventions: 2F", "Pupils who reached 2F in language conventions.", "Derivation: reference levels are meant to mean the same thing whichever test was used. Whether they do is exactly what the debate is about."
  ),
  tribble(
    ~var, ~file, ~kind, ~label, ~description, ~gap,
    "VSO", "schooladviezen", "count", "Advice: special secondary (VSO)", "Pupils advised into special secondary education.", "",
    "PRO", "schooladviezen", "count", "Advice: practical education (PRO)", "Pupils advised into praktijkonderwijs, the most supported track.", "",
    "VMBO_B", "schooladviezen", "count", "Advice: VMBO basic", "VMBO basisberoepsgerichte leerweg.", "",
    "VMBO_B_K", "schooladviezen", "count", "Advice: VMBO basic / kader", "Split advice between VMBO-B and VMBO-K.", "Derivation: split advice has to go somewhere when you collapse categories. Here it counts halfway on the ladder.",
    "VMBO_K", "schooladviezen", "count", "Advice: VMBO kader", "VMBO kaderberoepsgerichte leerweg.", "",
    "VMBO_K_GT", "schooladviezen", "count", "Advice: VMBO kader / GT", "Split advice between VMBO-K and VMBO-GT.", "",
    "VMBO_GT", "schooladviezen", "count", "Advice: VMBO GT", "VMBO gemengde/theoretische leerweg, the most academic VMBO track.", "",
    "VMBO_GT_HAVO", "schooladviezen", "count", "Advice: VMBO GT / HAVO", "Split advice between VMBO-GT and HAVO.", "",
    "HAVO", "schooladviezen", "count", "Advice: HAVO", "Senior general secondary education.", "",
    "HAVO_VWO", "schooladviezen", "count", "Advice: HAVO / VWO", "Split advice between HAVO and VWO.", "",
    "VWO", "schooladviezen", "count", "Advice: VWO", "Pre-university education, the most academic track.", "",
    "ADVIES_NIET_MOGELIJK", "schooladviezen", "count", "No advice possible", "Pupils for whom no advice could be given.", "Recording: the final advice includes any upward reconsideration after the test, so it mixes the teacher's view and the test's."
  ),
  tribble(
    ~var, ~file, ~kind, ~label, ~description, ~gap,
    "OVT", "schoolweging", "id", "Inspectorate school-location code", "Looks like \"00AP|C1\": school code, then a location number of the Inspectorate's own.", "Consistency: C1/C2 do not correspond to VESTIGINGSCODE 00/01. The dashboard matches multi-location schools by name (see sw_match).",
    "schoolweging", "schoolweging", "num", "Schoolweging 2024-25", "The school's weighting for disadvantage, calculated by CBS from parents' education, income, debt and origin of pupils. Higher = more disadvantaged. Roughly 20-40.", "Consistency: data/get-data.R calls the 2024-2025 sheet a three-year average, but that sheet is a single year; the three-year average is its own sheet (schoolweging_3y below).",
    "schoolweging_3y", "schoolweging", "num", "Schoolweging, 3-year average", "Average of 2022-23, 2023-24 and 2024-25, which the Inspectorate uses to smooth year-to-year noise.", "",
    "spreiding", "schoolweging", "num", "Spread of schoolweging within the school", "How much pupils' individual weightings vary within the school: a mixed population has a high spread.", "Derivation: two schools with the same schoolweging can have very different populations.",
    "aantal_leerlingen", "schoolweging", "num", "Pupils in the school", "All pupils the weighting is based on (the whole school, not just group 8).", ""
  ),
  tribble(
    ~var, ~file, ~kind, ~label, ~description, ~gap,
    "provider", "derived", "cat", "Which test the school used", "The one provider with a non-zero count, or \"Multiple\" / \"None\".", "Selection: schools CHOSE their test. Any difference between providers mixes test differences with differences between the schools that chose them.",
    "sw_match", "derived", "cat", "How the schoolweging was joined", "Unique school code, fuzzy name match, ambiguous, or no row at all.", "Selection: 315 schools have no schoolweging row. Most are Sbo, so it isn't random.",
    "score_z", "derived", "derived", "Score as z-score within provider", "(school average - provider mean) / provider SD, over single-provider schools.", "Derivation: by construction every provider has mean 0 and SD 1, so this variable CANNOT show a difference between providers. It only ranks schools within their own test.",
    "n_tested", "derived", "derived", "Group-8 pupils tested", "Sum of the _AANTAL columns of the providers the school used.", "Recording: follows the \"<5\" setting.",
    "pct_target", "derived", "derived", "Performance score: % reaching target level", "The mean of three percentages: maths % at 1S, reading % at 2F, language conventions % at 2F. Same definition as the score in assignment 1 and the closest this open data gets to the Volkskrant's comparison.", "Derivation: an unweighted mean of three subtest percentages, per school location. The assignment-1 script sums locations per school code first and reads \"<5\" as NA and then drops it in sum(na.rm = TRUE), which is the same as the \"zero\" setting here. The Volkskrant probably worked from pupil-level data.",
    "pct_lv_2F", "derived", "derived", "Reading: % reaching 2F", "100 x LV_2F / (LV_LAGER1F + LV_1F + LV_2F).", "Derivation: a school-level percentage. Small schools jump between extremes, and every school counts equally in an unweighted mean.",
    "pct_lv_below1F", "derived", "derived", "Reading: % below 1F", "100 x LV_LAGER1F / reading total.", "",
    "pct_rek_1S", "derived", "derived", "Maths: % reaching 1S", "100 x (REKENEN_1S + REKENEN_2F) / maths total.", "",
    "pct_rek_below1F", "derived", "derived", "Maths: % below 1F", "100 x REKENEN_LAGER1F / maths total.", "",
    "pct_tv_2F", "derived", "derived", "Language conventions: % reaching 2F", "100 x TV_2F / language-conventions total.", "",
    "pct_havo_plus", "derived", "derived", "Advice: % HAVO or higher", "100 x (HAVO + HAVO_VWO + VWO) / all regular advice (PRO ... VWO, excluding VSO and 'not possible').", "Derivation: whether VMBO_GT_HAVO counts as HAVO+ is a choice. Here it doesn't.",
    "pct_vwo", "derived", "derived", "Advice: % VWO", "100 x VWO / all regular advice.", "Recording: VWO counts are often \"<5\", so this variable reacts strongly to the \"<5\" setting.",
    "pct_vmbo_bk", "derived", "derived", "Advice: % PRO to VMBO-K", "100 x (PRO + VMBO_B + VMBO_B_K + VMBO_K) / all regular advice.", "",
    "advice_mean", "derived", "derived", "Advice: mean track level", "Mean position on the ladder PRO = 1, VMBO-B = 2, VMBO-K = 3, VMBO-GT = 4, HAVO = 5, VWO = 6; split advice halfway.", "Derivation: treats the tracks as equally spaced numbers, which they aren't."
  )
)
