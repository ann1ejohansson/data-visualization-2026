# Doorstroomtoets explorer
#
# An exploratory Shiny dashboard of the 2024-25 DUO school-level data on the
# doorstroomtoets, built around the question the Volkskrant asked: does the
# test a school picks change what its pupils are told they can do?
#
# Run from the project root:   shiny::runApp("dashboard")
# (data/get-data.R has to have run first, so data/raw/ exists)
#
# Files:
#   helpers/prepare-data.R  read + join the raw files; derive school-level variables
#   helpers/codebook.R      what every variable means, and what to watch out for
#   helpers/plots.R         shared ggplot theme and binning helpers

library(shiny)
library(bslib)
library(dplyr)
library(tidyr)
library(ggplot2)
library(plotly)

source("helpers/prepare-data.R")
source("helpers/plots.R")
source("helpers/codebook.R")

# ---- data (once, at start-up) -------------------------------------------------
# Reading the .ods is the slow part, so the joined table is cached next to
# the app. Delete .cache/ to rebuild after re-running get-data.R.
cache_file <- file.path(".cache", "prepared.rds")
if (file.exists(cache_file)) {
  D <- readRDS(cache_file)
} else {
  D <- prepare_data("../data/raw")
  dir.create(".cache", showWarnings = FALSE)
  saveRDS(D, cache_file)
}
S0 <- D$schools
PROVINCES <- sort(unique(S0$PROVINCIE))
DERIVED_MID <- derive_vars(S0, "mid") # used for the codebook's header row

provider_choice_names <- lapply(names(PROVIDER_COLOURS), function(p) {
  tags$span(
    tags$span(class = "swatch", style = paste0("background:", PROVIDER_COLOURS[[p]])),
    p, tags$small(class = "text-muted", paste0(" ", sum(S0$provider == p)))
  )
})

# small reusable UI pieces
gap_note <- function(type, ...) {
  div(class = "gap-note", span(class = "gap-tag", type), span(...))
}
look_for <- function(...) div(class = "look-for", strong("Look for: "), ...)


# ---- codebook UI (built once) --------------------------------------------------

cb_source <- function(file) {
  switch(file, eindscores = D$eind, referentieniveaus = D$ref, schooladviezen = D$adv, schoolweging = D$sw, derived = DERIVED_MID)
}

cb_header_stat <- function(row) {
  x <- cb_source(row$file)[[row$var]]
  n <- length(x)
  switch(row$kind,
    count = paste0(fmt(100 * mean(x == "<5"), 1), "% “<5”"),
    score = paste0(fmt(100 * mean(is.na(parse_dec(x)) | x == "NA"), 1), "% NA"),
    num = , derived = paste0(fmt(100 * mean(!is.finite(as.numeric(x))), 1), "% missing"),
    cat = paste0(length(unique(x)), " categories"),
    id = paste0(format(length(unique(x)), big.mark = ","), " distinct"),
    const = "constant"
  )
}

codebook_panels <- lapply(seq_len(nrow(CODEBOOK)), function(i) {
  row <- CODEBOOK[i, ]
  accordion_panel(
    value = row$var,
    title = div(
      class = "cb-row",
      span(class = "cb-var", row$var),
      span(class = "cb-label", row$label),
      span(class = "cb-file", row$file),
      span(class = "cb-kind", row$kind),
      span(class = "cb-stat", cb_header_stat(row))
    ),
    layout_columns(
      col_widths = c(5, 7),
      div(
        p(row$description),
        if (nzchar(row$gap)) gap_note(sub(":.*$", "", row$gap), sub("^[^:]*: ", "", row$gap)),
        tableOutput(paste0("cb_tab_", i))
      ),
      plotOutput(paste0("cb_plot_", i), height = "260px")
    )
  )
})


# ---- UI ------------------------------------------------------------------------

sidebar_filters <- sidebar(
  width = 290,
  title = "Filters (apply to every tab)",
  radioButtons(
    "suppressed", "Counts shown as “<5” are read as...",
    choices = c("the midpoint, 2.5" = "mid", "zero" = "zero", "missing: drop the school" = "drop")
  ),
  helpText("DUO hides counts of 1-4 pupils. 22% of reference-level cells and 39% of advice cells are “<5”, so this choice moves every percentage in the app."),
  checkboxGroupInput(
    "providers", "Test provider",
    choiceNames = provider_choice_names, choiceValues = names(PROVIDER_COLOURS),
    selected = setdiff(names(PROVIDER_COLOURS), "None")
  ),
  radioButtons("soort", "School type", c("All" = "All", "Regular (Bo)" = "Bo", "Special (Sbo)" = "Sbo"), inline = TRUE),
  selectInput("province", "Province", c("All provinces" = "All", PROVINCES)),
  sliderInput("min_n", "Minimum group-8 pupils tested", min = 0, max = 40, value = 0, step = 5),
  div(class = "in-view", textOutput("n_view"))
)

ui <- page_navbar(
  title = "Six tests, one advice?",
  id = "nav",
  theme = bs_theme(version = 5, preset = "cosmo", primary = "#1d1c1a", "font-size-base" = "0.95rem"),
  fillable = FALSE,
  sidebar = sidebar_filters,
  header = tags$head(tags$style(HTML("
    .swatch{display:inline-block;width:10px;height:10px;border-radius:2px;margin-right:6px;vertical-align:baseline}
    .in-view{font-weight:600;border-top:1px solid #e6e3dc;padding-top:10px}
    .gap-note{background:#f6f4ef;border-radius:6px;padding:8px 12px;margin:8px 0;font-size:.9rem}
    .gap-tag{display:inline-block;font-weight:700;text-transform:uppercase;font-size:.72rem;letter-spacing:.05em;margin-right:8px;color:#8a3b12}
    .look-for{font-size:.92rem;color:#3b3a36;margin:6px 0 10px}
    .accordion-button .accordion-title{flex:1 1 auto;min-width:0}
    .cb-row{display:grid;grid-template-columns:230px 1fr 140px 80px 150px;gap:12px;width:100%;align-items:baseline}
    .cb-var{font-family:SFMono-Regular,Menlo,Consolas,monospace;font-size:.85rem;font-weight:600}
    .cb-file,.cb-kind,.cb-stat{color:#6d6b64;font-size:.85rem}
    .cb-head{padding:0 3.2rem 6px 1.25rem;font-size:.75rem;text-transform:uppercase;letter-spacing:.05em;color:#6d6b64}
    .principle{border-left:none;padding:0}
    .principle h6{margin-bottom:2px}
    .big-num{font-size:1.9rem;font-weight:700;line-height:1.1}
  "))),

  # ---- 0. start here -------------------------------------------------------------
  nav_panel(
    "Start here",
    layout_columns(
      col_widths = c(7, 5),
      card(
        card_header("The question"),
        h4("Does the test a school picks change what its pupils are told they can do?"),
        p("Since 2023-24 every Dutch primary school chooses one of six approved doorstroomtoetsen for its group-8 pupils. The result feeds into the secondary-school advice (PRO, VMBO, HAVO, VWO). Volkskrant analyses in 2025 found that results, and the advice that follows, differ by provider even between schools with the same schoolweging. On 2 July 2026 the State Secretary announced a plan to go from six tests to one by 2029/30: “full comparability is a utopia”."),
        p("This dashboard uses DUO's open data for 2024-25, one row per school location, to see how much of that story you can check yourself, and where the data stops being able to tell you."),
        p(class = "text-muted small", "Background and sources: data/doorstroomtoetsen-context.md and data/data-context.md.")
      ),
      card(
        card_header("Keep in mind"),
        gap_note("Selection", "Schools chose their test. A raw provider comparison mixes a test effect with a school-population effect; the schoolweging tab tries to separate them."),
        gap_note("Consistency", "Raw scores are on six unrelated scales (IEP around 53-90, AMN around 316-456). Compare reference levels or advice instead."),
        gap_note("Derivation", "This is school-level, aggregated data. The Volkskrant probably had pupil-level data. A school mean is not a pupil.")
      )
    ),
    layout_columns(
      col_widths = c(7, 5),
      card(
        card_header("Who ends up in an analysis?"),
        p(class = "small text-muted", "Each extra requirement drops schools, and not at random. Grey bar = all schools in the file; dark bar = what is left."),
        plotOutput("funnel", height = "300px")
      ),
      card(
        card_header("Before you trust a chart, ask..."),
        div(class = "principle", h6("Selection"), p(class = "small", "What is included or excluded, and does that match the reality I want to say something about? (Sbo schools have no schoolweging; exempted pupils aren't tested.)")),
        div(class = "principle", h6("Missing data"), p(class = "small", "How do I handle it, and could it change the result? (Flip the “<5” setting in the sidebar and watch the numbers move.)")),
        div(class = "principle", h6("Recording"), p(class = "small", "Are the values reliable? (Counts are stored as text; provider scores live on different scales.)")),
        div(class = "principle", h6("Derivation"), p(class = "small", "Do my computed variables capture what they claim? (“% HAVO+” is a choice of categories; a z-score within provider erases provider differences.)")),
        div(class = "principle", h6("Consistency"), p(class = "small", "Did anything change across time, place or source? (Location codes differ between files; schoolweging exists per year and as a 3-year average.)"))
      )
    )
  ),

  # ---- 1. distributions ------------------------------------------------------------
  nav_panel(
    "1 · Distributions",
    card(
      card_header("Look at the whole distribution first"),
      layout_columns(
        col_widths = c(5, 3, 2, 2),
        selectInput("d_var", "Variable", NUM_VARS, selected = "pct_lv_2F"),
        radioButtons("d_split", "One row per", c("Provider" = "provider", "School type" = "SOORT_PO", "None" = "all"), inline = TRUE),
        radioButtons("d_y", "Bar height", c("Count" = "count", "% of row" = "share"), inline = TRUE),
        sliderInput("d_bins", "Bins", 10, 80, 30, step = 5)
      ),
      look_for("the shape (one peak or several?), the long tails of small schools, and the difference between Count and % of row: LIB and IEP dominate the counts, and switching to % lets the small providers be seen. Pick the raw score and split by None to see six scales stacked on top of each other."),
      plotlyOutput("dist_plot", height = "560px"),
      tableOutput("dist_table"),
      gap_note("Derivation", "Each school is one observation, whether it tested 6 pupils or 130. Try the minimum-pupils slider: small schools produce the 0% and 100% spikes.")
    )
  ),

  # ---- 2. relationships -------------------------------------------------------------
  nav_panel(
    "2 · Relationships",
    layout_columns(
      col_widths = c(8, 4),
      card(
        card_header("Any two variables against each other"),
        layout_columns(
          col_widths = c(4, 4, 4),
          selectInput("s_x", "x axis", NUM_VARS, selected = "schoolweging"),
          selectInput("s_y", "y axis", NUM_VARS, selected = "pct_lv_2F"),
          selectInput("s_focus", "Highlight", c("All providers" = "All", setNames(PROVIDERS, paste("Only", PROVIDERS))))
        ),
        layout_columns(
          col_widths = c(6, 6),
          radioButtons("s_col", "Colour by", c("Provider" = "provider", "School type" = "SOORT_PO", "Nothing" = "none"), inline = TRUE),
          checkboxInput("s_trend", "Show binned means (10 equal-sized bins per colour)", TRUE)
        ),
        look_for("whether the provider lines run parallel (a constant offset between tests), cross, or overlap. A line is a summary of many points; check that the cloud agrees with it."),
        plotlyOutput("scatter", height = "520px"),
        textOutput("scatter_stat"),
        gap_note("Selection", "Schools missing on either axis are silently dropped from a scatter plot. The count above tells you how many.")
      ),
      card(card_header("Selected school"), p(class = "small text-muted", "Click a point to see the raw counts behind it."), uiOutput("school_detail"), plotOutput("school_bars", height = "300px"))
    )
  ),

  # ---- 3. equal schoolweging ---------------------------------------------------------
  nav_panel(
    "3 · Equal schoolweging",
    card(
      card_header("The Volkskrant check: compare providers among similar schools"),
      p("Raw provider differences mix two things: how each test scores, and which schools chose it. Here schools are grouped into bands of equal schoolweging, and each provider's mean outcome is drawn per band. If the lines still sit apart within a band, school population alone doesn't explain the gap."),
      layout_columns(
        col_widths = c(4, 2, 3, 3),
        selectInput("v_out", "Outcome", OUTCOME_VARS, selected = "pct_lv_2F"),
        radioButtons("v_band", "Band width", c(1, 2, 4), selected = 2, inline = TRUE),
        radioButtons("v_w", "Average", c("Each school counts once" = "schools", "Weight by pupils" = "pupils")),
        sliderInput("v_min", "Hide bands with fewer schools than", 3, 30, 10)
      ),
      plotlyOutput("vk_plot", height = "430px"),
      h6("Where each provider's schools sit on schoolweging (box = middle 50%, line = 10th-90th percentile)"),
      plotOutput("vk_comp", height = "210px"),
      layout_columns(
        col_widths = c(3, 3, 6),
        selectInput("v_a", "Provider A", PROVIDERS, "LIB"),
        selectInput("v_b", "Provider B", PROVIDERS, "ROUTE8"),
        uiOutput("vk_gap")
      ),
      gap_note("Derivation", "Averaging within bands is a crude version of “controlling for” schoolweging. It only compares providers where both have enough schools, and it treats schoolweging as the only confounder. Region and denomination are also linked to provider choice (try the province filter)."),
      gap_note("Selection", "Sbo schools have no schoolweging and are always excluded here.")
    )
  ),

  # ---- 4. compare groups ------------------------------------------------------------
  nav_panel(
    "4 · Compare groups",
    card(
      card_header("Same numbers, different messages"),
      layout_columns(
        col_widths = c(4, 3, 5),
        selectInput("g_var", "Variable", NUM_VARS, selected = "pct_havo_plus"),
        radioButtons("g_by", "Group by", c("Provider" = "provider", "Province" = "PROVINCIE", "Denomination" = "DENOMINATIE_VESTIGING", "School type" = "SOORT_PO"), inline = TRUE),
        radioButtons("g_mark", "Show", c("Bar of the mean" = "bar", "Median + middle 50%" = "dots", "Every school" = "strip"), inline = TRUE)
      ),
      layout_columns(
        col_widths = c(6, 6),
        radioButtons("g_axis", "Value axis", c("Include zero" = "zero", "Zoom to the data" = "fit"), inline = TRUE),
        radioButtons("g_sort", "Order", c("By value" = "value", "By number of schools" = "n", "A-Z" = "name"), inline = TRUE)
      ),
      look_for("how the story changes when you switch from bars to every school (the spread within a provider is much larger than the gap between them), and what a bar chart that doesn't start at zero does to a difference of a few percentage points."),
      plotOutput("grp_plot", height = "520px"),
      uiOutput("grp_warn")
    )
  ),

  # ---- 5. map --------------------------------------------------------------------------
  nav_panel(
    "5 · Map",
    layout_columns(
      col_widths = c(7, 5),
      card(
        card_header("Where is each test used?"),
        selectInput("m_col", "Colour by", c("Provider" = "provider", NUM_VARS), selected = "provider"),
        look_for("the regional clusters (IEP in the north, Route 8 in Limburg). Provider choice follows geography, so a provider comparison is partly a regional comparison."),
        plotlyOutput("map", height = "680px"),
        gap_note("Recording", "Schools are placed at the centre of their 4-digit postcode, so schools in one PC4 area sit on top of each other. Missing values are drawn as open grey circles instead of disappearing.")
      ),
      card(card_header("Selected school"), p(class = "small text-muted", "Click a school on the map."), uiOutput("school_detail_2"), plotOutput("school_bars_2", height = "300px"))
    )
  ),

  # ---- 6. codebook ------------------------------------------------------------------
  nav_panel(
    "Codebook",
    card(
      card_header("Codebook"),
      p("Every column of the four source files, then the variables this dashboard derives from them. Click a row to see its distribution and summary statistics. Raw columns are summarised over the rows of their own file; derived variables over the joined table, using the “<5” setting in the sidebar."),
      div(class = "cb-head cb-row", span("variable"), span("meaning"), span("file"), span("kind"), span("missing / suppressed")),
      accordion(id = "codebook", open = FALSE, multiple = TRUE, !!!codebook_panels)
    )
  ),
  nav_spacer(),
  nav_item(tags$span(class = "navbar-text small", "DUO open data, school year 2024-25"))
)


# ---- server --------------------------------------------------------------------------

server <- function(input, output, session) {
  derived <- reactive(derive_vars(S0, input$suppressed))

  view <- reactive({
    d <- derived()
    if (input$soort != "All") d <- filter(d, SOORT_PO == input$soort)
    if (input$province != "All") d <- filter(d, PROVINCIE == input$province)
    d <- filter(d, provider %in% input$providers)
    if (input$min_n > 0) d <- filter(d, !is.na(n_tested), n_tested >= input$min_n)
    d
  })

  output$n_view <- renderText(paste0(format(nrow(view()), big.mark = ","), " of ", format(nrow(S0), big.mark = ","), " schools in view"))

  selected <- reactiveVal(NULL)
  # plotly warns until the plot has been drawn once; that is expected
  click_scatter <- reactive(suppressWarnings(event_data("plotly_click", source = "scatter")))
  click_map <- reactive(suppressWarnings(event_data("plotly_click", source = "map")))
  observeEvent(click_scatter(), selected(click_scatter()$customdata[[1]]))
  observeEvent(click_map(), selected(click_map()$customdata[[1]]))

  # ---- start here: selection funnel ----
  output$funnel <- renderPlot(res = 96, {
    s <- S0
    usable <- s$provider %in% PROVIDERS & !is.na(s$score_raw)
    steps <- tibble(
      step = c(
        "Schools (locations) in eindscores",
        "... with at least one pupil tested",
        "... one provider, usable average score",
        "... also in reference-level + advice files",
        "... also matched to a schoolweging",
        "... and in your current filter"
      ),
      n = c(
        nrow(s), sum(s$n_providers > 0), sum(usable),
        sum(usable & s$in_ref & s$in_adv),
        sum(usable & s$in_ref & s$in_adv & !is.na(s$schoolweging)),
        nrow(view())
      )
    ) |> mutate(step = factor(step, rev(step)))
    ggplot(steps, aes(y = step)) +
      geom_col(aes(x = nrow(s)), fill = "#e6e3dc", width = 0.7) +
      geom_col(aes(x = n), fill = INK, width = 0.7) +
      geom_text(aes(x = n, label = paste0(format(n, big.mark = ","), "  (", fmt(100 * n / nrow(s), 1), "%)")), hjust = -0.05, size = 3.8, colour = INK) +
      scale_x_continuous(expand = expansion(mult = c(0, 0.25)), labels = scales::label_comma()) +
      labs(x = "schools", y = NULL) +
      theme_dash(13) +
      theme(panel.grid.major.y = element_blank())
  })

  # ---- 1. distributions ----
  dist_data <- reactive({
    d <- view()
    grp <- if (input$d_split == "all") "all" else input$d_split
    if (grp == "all") d$all <- "All schools in view"
    b <- binned(d, input$d_var, grp, bins = input$d_bins, as_share = input$d_y == "share")
    list(b = b |> group_by(group) |> filter(sum(n) > 0) |> ungroup(), d = d, grp = grp)
  })

  output$dist_plot <- renderPlotly({
    dd <- dist_data()
    validate(need(!is.null(dd$b) && nrow(dd$b) > 0, "No schools left with a value for this variable. Loosen the filters or the \u201c<5\u201d setting."))
    cols <- if (dd$grp == "provider") PROVIDER_COLOURS else if (dd$grp == "SOORT_PO") TYPE_COLOURS else c("All schools in view" = INK_2)
    b <- dd$b |> mutate(
      group = droplevels(factor(group)),
      tip = paste0(group, "<br>", fmt(lo, 1), " to ", fmt(hi, 1), "<br>", n, " schools (", fmt(share, 1), "% of row)")
    )
    p <- ggplot(b, aes(x = x, y = y, fill = group, text = tip)) +
      geom_col(width = diff(b$lo[1:2]) * 0.92) +
      facet_grid(group ~ ., switch = "y") +
      scale_fill_manual(values = cols, guide = "none") +
      scale_y_continuous(n.breaks = 3) +
      labs(x = var_label(input$d_var), y = if (input$d_y == "count") "schools" else "% of row") +
      theme_dash() +
      theme(strip.text.y.left = element_text(angle = 0))
    ggplotly(p, tooltip = "text") |> layout(showlegend = FALSE) |> config(displayModeBar = FALSE)
  })

  output$dist_table <- renderTable(
    {
      dd <- dist_data()
      dd$d |>
        group_by(group = .data[[dd$grp]]) |>
        reframe(num_summary(.data[[input$d_var]])) |>
        mutate(across(c(n, missing), as.integer))
    },
    digits = 2, striped = TRUE, spacing = "xs"
  )

  # ---- 2. relationships ----
  output$scatter <- renderPlotly({
    d <- view()
    x <- input$s_x
    y <- input$s_y
    col <- input$s_col
    d <- d |>
      filter(is.finite(.data[[x]]), is.finite(.data[[y]])) |>
      mutate(
        colour = if (col == "none") "all" else as.character(.data[[col]]),
        focus = input$s_focus == "All" | provider == input$s_focus,
        colour = factor(ifelse(focus, colour, "other"), levels = c(names(PROVIDER_COLOURS), names(TYPE_COLOURS), "all", "other")),
        tip = paste0("<b>", INSTELLINGSNAAM_VESTIGING, "</b> (", tools::toTitleCase(tolower(PLAATSNAAM)), ")<br>", provider, "<br>", var_label(x), ": ", fmt(.data[[x]], 2), "<br>", var_label(y), ": ", fmt(.data[[y]], 2))
      ) |>
      arrange(focus)
    cols <- c(PROVIDER_COLOURS, TYPE_COLOURS, all = INK, other = "#d3d0c7")
    p <- ggplot(d, aes(.data[[x]], .data[[y]])) +
      geom_point(aes(colour = colour, text = tip, customdata = id), alpha = 0.45, size = 1.4) +
      scale_colour_manual(values = cols, name = NULL, breaks = setdiff(levels(droplevels(d$colour)), "other")) +
      labs(x = var_label(x), y = var_label(y)) +
      theme_dash()
    if (isTRUE(input$s_trend)) {
      bm <- binned_means(filter(d, focus), x, y, "colour")
      if (nrow(bm)) p <- p + geom_line(data = bm, aes(x = x, y = y, colour = group), linewidth = 1.1, inherit.aes = FALSE)
    }
    if (!is.null(selected()) && selected() %in% d$id) {
      p <- p + geom_point(data = filter(d, id == selected()), shape = 21, size = 4, stroke = 1.2, colour = INK, fill = NA)
    }
    ggplotly(p, tooltip = "text", source = "scatter") |>
      event_register("plotly_click") |>
      layout(legend = list(orientation = "h", y = -0.15)) |>
      config(displayModeBar = FALSE)
  })

  output$scatter_stat <- renderText({
    d <- view()
    ok <- is.finite(d[[input$s_x]]) & is.finite(d[[input$s_y]])
    r <- if (sum(ok) > 2) cor(d[[input$s_x]][ok], d[[input$s_y]][ok]) else NA
    paste0("Pearson r = ", fmt(r, 2), "  ·  n = ", format(sum(ok), big.mark = ","), " schools  ·  ", format(sum(!ok), big.mark = ","), " schools in view dropped because x or y is missing")
  })

  school_detail_ui <- function() {
    i <- selected()
    if (is.null(i)) return(p(em("No school selected yet.")))
    s <- derived()[i, ]
    used <- PROVIDERS[sapply(PROVIDERS, function(p) s[[paste0(p, "_AANTAL")]] != "0")]
    tagList(
      h5(s$INSTELLINGSNAAM_VESTIGING),
      p(class = "small text-muted", paste0(tools::toTitleCase(tolower(s$PLAATSNAAM)), " · ", s$PROVINCIE, " · ", s$SOORT_PO, " · ", s$DENOMINATIE_VESTIGING, " · ", s$INSTELLINGSCODE, "-", s$VESTIGINGSCODE)),
      tags$table(
        class = "table table-sm small",
        tags$tbody(
          lapply(used, function(p) tags$tr(tags$td(tags$span(class = "swatch", style = paste0("background:", PROVIDER_COLOURS[[p]])), PROVIDER_NAMES[[p]]), tags$td(paste0(s[[paste0(p, "_AANTAL")]], " pupils")), tags$td(paste0("avg ", s[[paste0(p, "_GEM")]] |> parse_dec() |> fmt(1))))),
          tags$tr(tags$td("Schoolweging (2024-25)"), tags$td(fmt(s$schoolweging, 2)), tags$td(as.character(s$sw_match))),
          tags$tr(tags$td("Reading % 2F / maths % 1S"), tags$td(paste0(fmt(s$pct_lv_2F, 0), "% / ", fmt(s$pct_rek_1S, 0), "%")), tags$td("")),
          tags$tr(tags$td("Advice % HAVO+"), tags$td(paste0(fmt(s$pct_havo_plus, 0), "%")), tags$td(""))
        )
      )
    )
  }
  school_bars_plot <- function() {
    i <- selected()
    req(i)
    s <- S0[i, ]
    short_adv <- c("PRO", "B", "B/K", "K", "K/GT", "GT", "GT/H", "HAVO", "H/V", "VWO")
    bars <- tibble(
      row = rep(c("Maths", "Reading", "Lang. conv.", "Advice"), c(3, 3, 3, 10)),
      level = c("<1F", "1F", "1S", "<1F", "1F", "2F", "<1F", "1F", "2F", short_adv),
      shade = c(rep(c("low", "mid", "target"), 3), short_adv),
      raw = c(
        s$REKENEN_LAGER1F, s$REKENEN_1F, s$REKENEN_1S, s$LV_LAGER1F, s$LV_1F, s$LV_2F,
        s$TV_LAGER1F, s$TV_1F, s$TV_2F, unlist(s[names(ADV_LEVEL)])
      )
    ) |>
      filter(!is.na(raw), raw != "0") |>
      mutate(
        n = count_value(raw, "mid"),
        row = factor(row, c("Advice", "Lang. conv.", "Reading", "Maths")),
        shade = factor(shade, c("low", "mid", "target", short_adv)),
        label = ifelse(raw == "<5", paste0(level, "\n<5"), paste0(level, "\n", raw))
      )
    validate(need(nrow(bars) > 0, "No reference-level or advice rows for this school."))
    pal <- c(low = "#e3a08a", mid = "#d6d2c8", target = "#86b6ef", setNames(colorRampPalette(c("#e8f0fb", "#86b6ef"))(10), short_adv))
    ggplot(bars, aes(x = n, y = row, fill = shade)) +
      geom_col(position = position_stack(reverse = TRUE), colour = "white", linewidth = 0.6, width = 0.8) +
      geom_text(aes(label = label), position = position_stack(vjust = 0.5, reverse = TRUE), size = 2.6, lineheight = 0.85, colour = INK) +
      scale_fill_manual(values = pal, guide = "none") +
      labs(x = "pupils (a \u201c<5\u201d cell is drawn as 2.5)", y = NULL) +
      theme_dash(11) +
      theme(panel.grid.major.y = element_blank())
  }
  output$school_detail <- renderUI(school_detail_ui())
  output$school_detail_2 <- renderUI(school_detail_ui())
  output$school_bars <- renderPlot(school_bars_plot(), res = 96)
  output$school_bars_2 <- renderPlot(school_bars_plot(), res = 96)

  # ---- 3. equal schoolweging ----
  vk_data <- reactive({
    band <- as.numeric(input$v_band)
    out <- input$v_out
    d <- view() |>
      filter(provider %in% PROVIDERS, is.finite(schoolweging), is.finite(.data[[out]])) |>
      mutate(w = if (input$v_w == "pupils") n_tested else 1) |>
      filter(is.finite(w)) |>
      mutate(
        band_lo = floor(schoolweging / band) * band,
        band_mid = band_lo + band / 2,
        provider = droplevels(provider)
      )
    cells <- d |>
      group_by(provider, band_lo, band_mid) |>
      summarise(value = weighted.mean(.data[[out]], w), n = n(), .groups = "drop") |>
      filter(n >= input$v_min)
    list(d = d, cells = cells, band = band, xlim = if (nrow(cells)) c(min(cells$band_lo), max(cells$band_lo) + band) else c(20, 40))
  })

  output$vk_plot <- renderPlotly({
    v <- vk_data()
    validate(need(nrow(v$cells) > 0, "No schoolweging band has enough schools for any provider. Lower the minimum, widen the bands, or change the \u201c<5\u201d setting (\u201cdrop the school\u201d removes almost every school from the advice variables)."))
    cl <- v$cells |>
      arrange(provider, band_lo) |>
      group_by(provider) |>
      mutate(run = cumsum(c(1, diff(band_lo) > v$band + 1e-9))) |>
      ungroup() |>
      mutate(tip = paste0(provider, "<br>schoolweging ", band_lo, " to ", band_lo + v$band, "<br>", fmt(value, 2), " (", n, " schools)"))
    ends <- cl |> group_by(provider) |> slice_max(band_lo, n = 1)
    p <- ggplot(cl, aes(band_mid, value, colour = provider)) +
      geom_line(aes(group = interaction(provider, run)), linewidth = 0.9) +
      geom_point(aes(size = n, text = tip)) +
      geom_text(data = ends, aes(label = provider), nudge_x = v$band * 0.6, hjust = 0, size = 3.5, show.legend = FALSE) +
      scale_colour_manual(values = PROVIDER_COLOURS, name = NULL) +
      scale_size_area(max_size = 6, guide = "none") +
      scale_x_continuous(expand = expansion(mult = c(0.02, 0.1))) +
      labs(x = "schoolweging band (higher = more disadvantaged pupil population)", y = var_label(input$v_out)) +
      theme_dash()
    ggplotly(p, tooltip = "text") |> layout(legend = list(orientation = "h", y = -0.2)) |> config(displayModeBar = FALSE)
  })

  output$vk_comp <- renderPlot(res = 96, {
    v <- vk_data()
    d <- v$d
    req(nrow(d) > 0)
    comp <- d |>
      group_by(provider) |>
      summarise(p10 = quantile(schoolweging, .1), q1 = quantile(schoolweging, .25), med = median(schoolweging), q3 = quantile(schoolweging, .75), p90 = quantile(schoolweging, .9), n = n()) |>
      mutate(provider = factor(provider, rev(PROVIDERS)))
    ggplot(comp, aes(y = provider, colour = provider)) +
      geom_linerange(aes(xmin = p10, xmax = p90), linewidth = 0.6) +
      geom_linerange(aes(xmin = q1, xmax = q3), linewidth = 5) +
      geom_point(aes(x = med), colour = "white", size = 1.6) +
      geom_text(aes(x = p90, label = paste0("  n = ", n, ", median ", fmt(med, 1))), hjust = 0, colour = INK_2, size = 3.3) +
      scale_colour_manual(values = PROVIDER_COLOURS, guide = "none") +
      coord_cartesian(xlim = v$xlim + c(0, 0.25 * diff(v$xlim))) +
      labs(x = "schoolweging (same range as the chart above)", y = NULL) +
      theme_dash()
  })

  output$vk_gap <- renderUI({
    v <- vk_data()
    a <- input$v_a
    b <- input$v_b
    wm <- function(p) {
      x <- filter(v$d, provider == p)
      weighted.mean(x[[input$v_out]], x$w)
    }
    raw <- wm(a) - wm(b)
    both <- inner_join(filter(v$cells, provider == a), filter(v$cells, provider == b), by = "band_lo", suffix = c("_a", "_b"))
    within <- if (nrow(both)) weighted.mean(both$value_a - both$value_b, both$n_a + both$n_b) else NA
    sw <- function(p) mean(filter(v$d, provider == p)$schoolweging)
    sgn <- function(x) paste0(ifelse(is.finite(x) & x > 0, "+", ""), fmt(x, 2))
    layout_columns(
      col_widths = c(6, 6),
      div(div(class = "small text-muted", paste(a, "minus", b, ", all schools")), div(class = "big-num", sgn(raw))),
      div(div(class = "small text-muted", paste0("... within equal-schoolweging bands (", nrow(both), " bands)")), div(class = "big-num", sgn(within))),
      p(class = "small text-muted", paste0("Mean schoolweging ", a, " ", fmt(sw(a), 1), " vs ", b, " ", fmt(sw(b), 1), ". If the two numbers above differ a lot, composition explains part of the raw gap."))
    )
  })

  # ---- 4. compare groups ----
  output$grp_plot <- renderPlot(res = 96, {
    d <- view()
    v <- input$g_var
    g <- input$g_by
    d <- d |>
      filter(is.finite(.data[[v]])) |>
      mutate(group = as.character(.data[[g]]))
    if (g == "DENOMINATIE_VESTIGING") {
      small <- d |> count(group) |> filter(n < 40) |> pull(group)
      d$group[d$group %in% small] <- "Other (smaller categories)"
    }
    st <- d |>
      group_by(group) |>
      summarise(mean = mean(.data[[v]]), q1 = quantile(.data[[v]], .25), med = median(.data[[v]]), q3 = quantile(.data[[v]], .75), n = n())
    key <- switch(input$g_sort, value = if (input$g_mark == "bar") st$mean else st$med, n = st$n, name = -rank(st$group))
    lev <- st$group[order(key)]
    st$group <- factor(st$group, lev)
    d$group <- factor(d$group, lev)
    fills <- if (g == "provider") PROVIDER_COLOURS else if (g == "SOORT_PO") TYPE_COLOURS else setNames(rep(INK_2, length(lev)), lev)

    p <- ggplot(st, aes(y = group)) +
      scale_fill_manual(values = fills, guide = "none") +
      scale_colour_manual(values = fills, guide = "none")
    if (input$g_mark == "bar") {
      p <- p + geom_col(aes(x = mean, fill = group), width = 0.65)
      rng <- range(st$mean)
    } else if (input$g_mark == "dots") {
      p <- p + geom_linerange(aes(xmin = q1, xmax = q3, colour = group), linewidth = 2.5, alpha = 0.5) +
        geom_point(aes(x = med, colour = group), size = 3.2)
      rng <- range(c(st$q1, st$q3))
    } else {
      p <- p + geom_jitter(data = d, aes(x = .data[[v]], y = group, colour = group), height = 0.25, width = 0, alpha = 0.25, size = 1) +
        geom_point(aes(x = med), shape = 124, size = 7, colour = INK)
      rng <- range(d[[v]])
    }
    p <- p + geom_text(aes(x = Inf, label = paste0("n = ", format(n, big.mark = ","))), hjust = 1.05, size = 3.3, colour = INK_2)
    lims <- if (input$g_axis == "zero") c(min(0, rng[1]), rng[2]) else rng + c(-0.15, 0.15) * diff(rng)
    p + coord_cartesian(xlim = c(lims[1], lims[2] + 0.18 * diff(lims))) +
      labs(x = var_label(v), y = NULL, caption = if (input$g_mark == "strip") "One dot per school; vertical tick = median." else NULL) +
      theme_dash(13) +
      theme(panel.grid.major.y = element_blank())
  })

  output$grp_warn <- renderUI({
    if (input$g_mark == "bar" && input$g_axis == "fit") {
      gap_note("Visual encoding", "A bar encodes its value by its length. With the axis zoomed in, the bars' lengths no longer match the numbers, so small differences look huge. Dots and lines don't have this problem, because we read their position, not their length.")
    }
  })

  # ---- 5. map ----
  output$map <- renderPlotly({
    validate(need(D$has_coords, "No coordinates: data/raw/postcodes_pc4.csv is missing (get-data.R doesn't download it)."))
    d <- view() |> filter(is.finite(lat))
    col <- input$m_col
    d <- d |> mutate(tip = paste0("<b>", INSTELLINGSNAAM_VESTIGING, "</b> (", tools::toTitleCase(tolower(PLAATSNAAM)), ")<br>", provider, if (col != "provider") paste0("<br>", var_label(col), ": ", fmt(.data[[col]], 2)) else ""))
    p <- ggplot(d, aes(lon, lat))
    if (col == "provider") {
      p <- p + geom_point(aes(colour = provider, text = tip, customdata = id), size = 1.2, alpha = 0.8) +
        scale_colour_manual(values = PROVIDER_COLOURS, name = NULL)
    } else {
      miss <- filter(d, !is.finite(.data[[col]]))
      p <- p + geom_point(data = miss, aes(text = tip, customdata = id), shape = 21, colour = "#9a978e", fill = NA, size = 1.3) +
        geom_point(data = filter(d, is.finite(.data[[col]])), aes(colour = .data[[col]], text = tip, customdata = id), size = 1.2) +
        scale_colour_gradient(low = "#cde2fb", high = "#0d366b", name = NULL)
    }
    p <- p + coord_quickmap() + labs(x = NULL, y = NULL) + theme_dash() +
      theme(axis.text = element_blank(), panel.grid.major = element_blank())
    ggplotly(p, tooltip = "text", source = "map") |>
      event_register("plotly_click") |>
      layout(legend = list(orientation = "h", y = -0.05)) |>
      config(displayModeBar = FALSE)
  })

  # ---- codebook ----
  lapply(seq_len(nrow(CODEBOOK)), function(i) {
    row <- CODEBOOK[i, ]
    values <- reactive({
      if (row$file == "derived") derived()[[row$var]] else cb_source(row$file)[[row$var]]
    })
    output[[paste0("cb_tab_", i)]] <- renderTable(
      {
        x <- values()
        stat <- switch(row$kind,
          const = tibble(statistic = "value(s)", value = paste(unique(x), collapse = ", ")),
          id = tibble(statistic = c("rows", "distinct values", "examples"), value = c(format(length(x), big.mark = ","), format(length(unique(x)), big.mark = ","), paste(head(unique(x), 3), collapse = " | "))),
          cat = {
            tb <- sort(table(x, useNA = "ifany"), decreasing = TRUE)
            tibble(statistic = names(tb), value = paste0(format(as.integer(tb), big.mark = ","), " (", fmt(100 * as.numeric(tb) / length(x), 1), "%)")) |> head(14)
          },
          count = {
            n <- suppressWarnings(as.numeric(x))
            s <- num_summary(n)
            tibble(
              statistic = c("rows", "zero", "“<5” (suppressed)", "reported numbers (0 or 5+)", "mean of reported numbers", "sd", "median", "IQR", "max"),
              value = c(format(length(x), big.mark = ","), paste0(sum(x == "0"), " (", fmt(100 * mean(x == "0"), 1), "%)"), paste0(sum(x == "<5"), " (", fmt(100 * mean(x == "<5"), 1), "%)"), format(s$n, big.mark = ","), fmt(s$mean, 2), fmt(s$sd, 2), fmt(s$median, 1), paste(fmt(s$q1, 1), "to", fmt(s$q3, 1)), fmt(s$max, 0))
            )
          },
          {
            n <- if (row$kind == "score") parse_dec(x) else as.numeric(x)
            if (row$kind == "score") {
              zero <- sum(n == 0, na.rm = TRUE)
              n[n == 0] <- NA
            }
            s <- num_summary(n)
            tibble(
              statistic = c("n (non-missing)", "missing", if (row$kind == "score") "0 (provider not used)", "mean", "sd", "min", "25th percentile", "median", "75th percentile", "max"),
              value = c(format(s$n, big.mark = ","), format(s$missing - if (row$kind == "score") zero else 0, big.mark = ","), if (row$kind == "score") format(zero, big.mark = ","), fmt(s$mean, 2), fmt(s$sd, 2), fmt(s$min, 2), fmt(s$q1, 2), fmt(s$median, 2), fmt(s$q3, 2), fmt(s$max, 2))
            )
          }
        )
        stat
      },
      striped = TRUE, spacing = "xs", colnames = FALSE
    )
    output[[paste0("cb_plot_", i)]] <- renderPlot(res = 96, {
      x <- values()
      if (row$kind %in% c("const", "id")) return(NULL)
      if (row$kind == "cat") {
        tb <- as.data.frame(sort(table(x), decreasing = TRUE)) |> head(15)
        names(tb) <- c("value", "n")
        tb$value <- factor(tb$value, rev(tb$value))
        return(ggplot(tb, aes(n, value)) + geom_col(fill = INK_2, width = 0.7) + labs(x = "rows", y = NULL) + theme_dash())
      }
      if (row$kind == "count") {
        tb <- tibble(raw = x) |>
          count(raw) |>
          mutate(value = count_value(raw, "mid"), type = case_when(raw == "<5" ~ "“<5” (1-4, position unknown)", raw == "0" ~ "zero", TRUE ~ "reported count"))
        return(ggplot(tb, aes(value, n, fill = type)) +
          geom_col(width = 0.9) +
          scale_fill_manual(values = c("reported count" = INK_2, "zero" = "#c4c1b8", "“<5” (1-4, position unknown)" = "#eb6834"), name = NULL) +
          labs(x = "pupils", y = "rows") +
          theme_dash())
      }
      n <- if (row$kind == "score") parse_dec(x) else as.numeric(x)
      if (row$kind == "score") n[n == 0] <- NA
      n <- n[is.finite(n)]
      if (!length(n)) return(NULL)
      ggplot(tibble(n), aes(n)) +
        geom_histogram(bins = 40, fill = INK_2, colour = "white", linewidth = 0.2) +
        geom_vline(xintercept = median(n), colour = "#eb6834", linewidth = 0.8) +
        labs(x = row$label, y = "rows", caption = "orange line = median") +
        theme_dash()
    })
  })
}

shinyApp(ui, server)
