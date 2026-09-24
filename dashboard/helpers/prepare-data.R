# prepare-data.R
#
# Reads the raw DUO / Inspectorate files that data/get-data.R downloads and
# builds ONE school-level table for the dashboard. Every step that changes
# what the data can tell us (a join that drops schools, a fuzzy match, a
# suppressed count) is kept visible as a column or a count, so the
# dashboard can show it instead of hiding it.
#
# Two stages, on purpose:
#   1. prepare_data()  - read + join. Nothing is imputed, "<5" stays "<5".
#   2. derive_vars()   - turn counts into percentages etc. This is where the
#                        analyst makes choices (how to treat "<5", which
#                        advice categories count as "HAVO or higher"), so
#                        it takes those choices as arguments and the
#                        dashboard lets you flip them.

library(dplyr)
library(readr)

PROVIDERS <- c("LIB", "IEP", "ROUTE8", "DIA", "AMN", "DOE")

PROVIDER_NAMES <- c(
  LIB = "Leerling in Beeld (Cito B.V.)",
  IEP = "IEP Eindtoets (Bureau ICE)",
  ROUTE8 = "Route 8 (A-VISION)",
  DIA = "Dia-Eindtoets (Diataal)",
  AMN = "AMN Eindtoets",
  DOE = "DOE (government test, Stichting Cito)",
  Multiple = "More than one provider",
  None = "No provider reported"
)

# One fixed colour per provider, in order of market share. Colour follows
# the provider everywhere in the app, so a filter never repaints a group.
PROVIDER_COLOURS <- c(
  LIB = "#2a78d6", IEP = "#eb6834", ROUTE8 = "#1baf7a", DIA = "#eda100",
  AMN = "#e87ba4", DOE = "#008300", Multiple = "#8f8c83", None = "#c4c1b8"
)
TYPE_COLOURS <- c(Bo = "#2a78d6", Sbo = "#eb6834")

REF_COLS <- c(
  "REKENEN_LAGER1F", "REKENEN_1F", "REKENEN_1S", "REKENEN_2F",
  "LV_LAGER1F", "LV_1F", "LV_2F", "TV_LAGER1F", "TV_1F", "TV_2F"
)
ADV_COLS <- c(
  "VSO", "PRO", "VMBO_B", "VMBO_B_K", "VMBO_K", "VMBO_K_GT", "VMBO_GT",
  "VMBO_GT_HAVO", "HAVO", "HAVO_VWO", "VWO", "ADVIES_NIET_MOGELIJK"
)
# ordinal position of each advice on the PRO (1) ... VWO (6) ladder;
# split advice sits halfway between its two tracks
ADV_LEVEL <- c(
  PRO = 1, VMBO_B = 2, VMBO_B_K = 2.5, VMBO_K = 3, VMBO_K_GT = 3.5,
  VMBO_GT = 4, VMBO_GT_HAVO = 4.5, HAVO = 5, HAVO_VWO = 5.5, VWO = 6
)


# ---- reading --------------------------------------------------------------

# DUO files: semicolon-separated, decimal comma. Read EVERYTHING as text
# first, so "<5" survives and we decide ourselves how to parse it.
read_duo <- function(path) {
  read_delim(
    path,
    delim = ";", quote = '"',
    col_types = cols(.default = col_character()),
    locale = locale(encoding = "UTF-8"),
    na = character(), show_col_types = FALSE
  )
}

parse_dec <- function(x) {
  suppressWarnings(
    as.numeric(sub(",", ".", x, fixed = TRUE))
  )
}

# similarity of two school names, 0-1 (1 = identical after cleaning)
name_sim <- function(a, b) {
  clean <- function(s) {
    s <- tolower(s)
    s <- gsub("basisschool|o\\.b\\.s\\.|^bs |r\\.k\\.|rk ", "", s)
    trimws(gsub("[^a-z0-9 ]", "", s))
  }
  a <- clean(a)
  b <- clean(b)
  1 - as.numeric(utils::adist(a, b)) / pmax(nchar(a), nchar(b), 1)
}


# ---- stage 1: read + join --------------------------------------------------

prepare_data <- function(raw_dir = "../data/raw") {
  f <- function(x) file.path(raw_dir, x)
  needed <- c(
    "eindscores_2024-2025.csv", "referentieniveaus_2024-2025.csv",
    "schooladviezen_2024-2025.csv", "schoolweging_2022-2025.ods"
  )
  missing <- needed[!file.exists(f(needed))]
  if (length(missing)) {
    stop(
      "Missing raw file(s): ", paste(missing, collapse = ", "),
      "\nRun data/get-data.R from the project root first."
    )
  }

  eind <- read_duo(f("eindscores_2024-2025.csv"))
  ref <- read_duo(f("referentieniveaus_2024-2025.csv"))
  adv <- read_duo(f("schooladviezen_2024-2025.csv"))

  sw_year <- readODS::read_ods(
    f("schoolweging_2022-2025.ods"),
    sheet = "2024-2025"
  )
  sw_3y <- readODS::read_ods(
    f("schoolweging_2022-2025.ods"),
    sheet = "Driejaarsgemiddelde"
  )
  # long header: "schoolweging 2022/2023, ..."
  names(sw_3y)[4] <- "schoolweging_3y"
  sw <- sw_year |>
    left_join(select(sw_3y, OVT, schoolweging_3y), by = "OVT") |>
    mutate(INSTELLINGSCODE = sub("\\|.*$", "", OVT))

  key <- c("INSTELLINGSCODE", "VESTIGINGSCODE")

  # which provider(s) did the school use? "0" = not used; a number or "<5" =
  # used
  used <- sapply(PROVIDERS, function(p) eind[[paste0(p, "_AANTAL")]] != "0")
  n_used <- rowSums(used)
  provider <- ifelse(
    n_used == 1, PROVIDERS[max.col(used, ties.method = "first")],
    ifelse(n_used == 0, "None", "Multiple")
  )

  schools <- eind |>
    mutate(
      provider = factor(provider, levels = names(PROVIDER_COLOURS)),
      n_providers = n_used,
      in_ref = paste(INSTELLINGSCODE, VESTIGINGSCODE) %in% paste(
        ref$INSTELLINGSCODE,
        ref$VESTIGINGSCODE
      ),
      in_adv = paste(INSTELLINGSCODE, VESTIGINGSCODE) %in% paste(
        adv$INSTELLINGSCODE,
        adv$VESTIGINGSCODE
      )
    ) |>
    left_join(select(ref, all_of(c(key, REF_COLS))), by = key) |>
    left_join(select(adv, all_of(c(key, ADV_COLS))), by = key)

  # -- schoolweging join ------------------------------------------------------
  # sw is keyed "INST|C1", "INST|C2": the location part does NOT follow
  # VESTIGINGSCODE (see the notes at the bottom of get-data.R). So:
  #   * 1 location in eindscores and 1 row in sw -> match on the school code
  #   * otherwise -> pick the sw row with the most similar name, if similar
  # enough
  n_loc <- count(schools, INSTELLINGSCODE, name = "n_loc_eind")
  n_sw <- count(sw, INSTELLINGSCODE, name = "n_loc_sw")
  schools <- schools |>
    left_join(n_loc, by = "INSTELLINGSCODE") |>
    left_join(n_sw, by = "INSTELLINGSCODE")

  sw_row <- rep(NA_integer_, nrow(schools))
  sw_match <- rep("no schoolweging row for this school code", nrow(schools))
  for (i in seq_len(nrow(schools))) {
    cand <- which(sw$INSTELLINGSCODE == schools$INSTELLINGSCODE[i])
    if (!length(cand)) next
    if (length(cand) == 1 && schools$n_loc_eind[i] == 1) {
      sw_row[i] <- cand
      sw_match[i] <- "unique school code"
    } else {
      sim <- name_sim(schools$INSTELLINGSNAAM_VESTIGING[i], sw$Naam[cand])
      if (max(sim) >= 0.6) {
        sw_row[i] <- cand[which.max(sim)]
        sw_match[i] <- "fuzzy name match (multi-location school)"
      } else {
        sw_match[i] <- "ambiguous (several locations, no confident name match)"
      }
    }
  }
  schools <- schools |>
    mutate(
      sw_match = factor(sw_match, levels = c(
        "unique school code", "fuzzy name match (multi-location school)",
        "ambiguous (several locations, no confident name match)",
        "no schoolweging row for this school code"
      )),
      sw_name = sw$Naam[sw_row],
      schoolweging = sw$schoolweging[sw_row],
      schoolweging_3y = sw$schoolweging_3y[sw_row],
      sw_spreiding = sw$spreiding[sw_row],
      sw_leerlingen = sw$aantal_leerlingen[sw_row]
    )

  # -- coordinates (optional) --------------------------------------------------
  # postcodes_pc4.csv is NOT downloaded by get-data.R; if it's there we use
  # it for the map, otherwise the map tab says so.
  if (file.exists(f("postcodes_pc4.csv"))) {
    pc <- read_csv(
      f("postcodes_pc4.csv"),
      col_types = cols(postcode = "c"),
      show_col_types = FALSE
    ) |>
      distinct(postcode, .keep_all = TRUE) |>
      select(pc4 = postcode, lat = latitude, lon = longitude)
    schools <- schools |>
      mutate(pc4 = substr(POSTCODE_VESTIGING, 1, 4)) |>
      left_join(pc, by = "pc4")
  } else {
    schools <- mutate(schools, lat = NA_real_, lon = NA_real_)
  }

  schools <- schools |>
    mutate(
      id = row_number(),
      SOORT_PO = factor(SOORT_PO, levels = c("Bo", "Sbo")),
      # raw score for single-provider schools; NA when suppressed/multi/none
      score_raw = mapply(function(p, i) {
        if (!p %in% PROVIDERS) {
          return(NA_real_)
        }
        parse_dec(eind[[paste0(p, "_GEM")]][i])
      }, as.character(provider), seq_len(n()))
    ) |>
    group_by(provider) |>
    mutate(score_z = (score_raw - mean(score_raw, na.rm = TRUE)) / sd(score_raw, na.rm = TRUE)) |>
    ungroup() |>
    mutate(score_z = ifelse(provider %in% PROVIDERS, score_z, NA_real_))

  list(
    schools = schools, eind = eind, ref = ref, adv = adv, sw = sw,
    has_coords = any(!is.na(schools$lat))
  )
}


# ---- stage 2: derived variables --------------------------------------------

# How to read a count cell. "<5" means 1, 2, 3 or 4 pupils.
#   "mid"  -> 2.5 (the midpoint: unbiased-ish on average, wrong for every
# school)
#   "zero" -> 0   (what a careless as.numeric() + replace_na(0) does)
#   "drop" -> NA  (the school drops out of every percentage that needs that
# cell)
count_value <- function(x, suppressed = c("mid", "zero", "drop")) {
  suppressed <- match.arg(suppressed)
  v <- suppressWarnings(as.numeric(x))
  v[!is.na(x) & x == "<5"] <- switch(suppressed,
    mid = 2.5,
    zero = 0,
    drop = NA_real_
  )
  v
}

derive_vars <- function(schools, suppressed = "mid") {
  cv <- function(col) count_value(schools[[col]], suppressed)
  pct <- function(num, den) ifelse(den > 0, 100 * num / den, NA_real_)

  # pupils tested: sum over the providers the school actually used
  tested <- sapply(PROVIDERS, function(p) {
    raw <- schools[[paste0(p, "_AANTAL")]]
    ifelse(raw == "0", 0, count_value(raw, suppressed))
  })

  r <- lapply(setNames(REF_COLS, REF_COLS), cv)
  a <- lapply(setNames(ADV_COLS, ADV_COLS), cv)
  rek_tot <- r$REKENEN_LAGER1F + r$REKENEN_1F + r$REKENEN_1S + r$REKENEN_2F
  lv_tot <- r$LV_LAGER1F + r$LV_1F + r$LV_2F
  tv_tot <- r$TV_LAGER1F + r$TV_1F + r$TV_2F
  # advice denominator: every pupil with a regular track advice (no VSO,
  # no "advice not possible")
  adv_tot <- Reduce(`+`, a[names(ADV_LEVEL)])
  adv_lvl <- Reduce(
    `+`,
    Map(function(col, w) w * a[[col]], names(ADV_LEVEL), ADV_LEVEL)
  )

  schools |>
    mutate(
      n_tested = ifelse(n_providers > 0, rowSums(tested), NA_real_),
      exempted = cv("ONTHEFFING_REDEN_ND"),
      pct_rek_1S = pct(r$REKENEN_1S + r$REKENEN_2F, rek_tot),
      pct_rek_below1F = pct(r$REKENEN_LAGER1F, rek_tot),
      pct_lv_2F = pct(r$LV_2F, lv_tot),
      pct_lv_below1F = pct(r$LV_LAGER1F, lv_tot),
      pct_tv_2F = pct(r$TV_2F, tv_tot),
      n_advice = adv_tot,
      pct_havo_plus = pct(a$HAVO + a$HAVO_VWO + a$VWO, adv_tot),
      pct_vwo = pct(a$VWO, adv_tot),
      pct_vmbo_bk = pct(a$PRO + a$VMBO_B + a$VMBO_B_K + a$VMBO_K, adv_tot),
      advice_mean = ifelse(adv_tot > 0, adv_lvl / adv_tot, NA_real_)
    )
}


# ---- the numeric variables the dashboard lets you pick ----------------------

NUM_VARS <- list(
  "Reference levels (meant to be comparable across tests)" = c(
    "Reading: % reaching target level 2F" = "pct_lv_2F",
    "Reading: % below basic level 1F" = "pct_lv_below1F",
    "Maths: % reaching target level 1S" = "pct_rek_1S",
    "Maths: % below basic level 1F" = "pct_rek_below1F",
    "Language conventions: % reaching 2F" = "pct_tv_2F"
  ),
  "Secondary-school advice" = c(
    "Advice: % HAVO or higher" = "pct_havo_plus",
    "Advice: % VWO" = "pct_vwo",
    "Advice: % PRO / VMBO-B / VMBO-K" = "pct_vmbo_bk",
    "Advice: mean track level (1 = PRO ... 6 = VWO)" = "advice_mean"
  ),
  "Test scores" = c(
    "Raw average score (six different scales!)" = "score_raw",
    "Score as z-score within provider" = "score_z"
  ),
  "School context" = c(
    "Schoolweging 2024-25 (higher = more disadvantaged)" = "schoolweging",
    "Schoolweging, 3-year average" = "schoolweging_3y",
    "Schoolweging spread within the school" = "sw_spreiding",
    "School size (pupils in schoolweging file)" = "sw_leerlingen",
    "Group-8 pupils tested" = "n_tested",
    "Pupils exempted from the test" = "exempted"
  )
)
OUTCOME_VARS <- NUM_VARS[c(1, 2)]
OUTCOME_VARS[["Test scores"]] <- c(
  "Score as z-score within provider" = "score_z"
)

var_label <- function(v) {
  all <- unlist(unname(NUM_VARS))
  names(all)[match(v, all)] %||% v
}
`%||%` <- function(a, b) if (is.null(a) || is.na(a)) b else a
