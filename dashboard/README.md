# Doorstroomtoets explorer (Shiny)

An exploratory dashboard of DUO's 2024-25 school-level doorstroomtoets data,
built around the Volkskrant question: *does the test a school picks change what
its pupils are told they can do?* It also contains a codebook with a
drop-down row per variable (description, data-reality gap to watch for,
summary statistics and a distribution plot).

## Run it

1. From the project root, run `data/get-data.R` once so `data/raw/` exists.
2. Install the packages (once):
   ```r
   install.packages(c("shiny", "bslib", "dplyr", "tidyr", "readr", "readODS", "ggplot2", "plotly"))
   ```
3. From the project root: `shiny::runApp("dashboard")`

The first start reads the `.ods` file and caches the joined table in
`dashboard/.cache/` (git-ignored). Delete that folder after re-downloading the
raw data.

The map needs `data/raw/postcodes_pc4.csv`, which `get-data.R` does not
download. Without it, the map tab says so and everything else works.

## What's where

| file | what it does |
|---|---|
| `app.R` | UI and server: filters, the six tabs, the codebook |
| `helpers/prepare-data.R` | reads and joins the four raw files (`prepare_data()`), then turns counts into school-level variables (`derive_vars()`) |
| `helpers/codebook.R` | one row per variable: meaning, source file, and the data-reality gap to watch for |
| `helpers/plots.R` | shared ggplot theme, summary and binning helpers |

## Tabs

- **Start here**: the question, what to keep in mind, and a selection funnel showing how many schools survive each join.
- **1 Distributions**: histograms split by provider or school type, count vs % of row.
- **2 Relationships**: any two variables, coloured by provider, with binned means and Pearson r; click a school to see its raw counts.
- **3 Equal schoolweging**: the Volkskrant check. Provider means within schoolweging bands, where each provider's schools sit on schoolweging, and a raw vs within-band gap for two providers.
- **4 Compare groups**: the same numbers as bars, median + IQR, or every school, with a zero-based or zoomed axis.
- **5 Map**: where each test is used, or any variable on the map.
- **Codebook**: every raw and derived variable.

The sidebar filters apply everywhere. The first one decides how the
privacy-suppressed `"<5"` counts are read (midpoint 2.5, zero, or drop the
school); it changes every derived percentage.

## Decisions baked into the data preparation

- A school's provider is the one provider with a non-zero count; schools with two or more are "Multiple".
- Schoolweging is joined on school code when a school has one location in both files. Multi-location schools are matched by name similarity (at least 0.6); the rest are left unmatched. `sw_match` records which happened.
- `% HAVO or higher` = (HAVO + HAVO_VWO + VWO) / all advice from PRO to VWO. VSO and "advice not possible" are left out of the denominator.
- `score_z` standardises each provider's raw score within that provider, so by construction it cannot show a difference *between* providers.
