# plots.R - small helpers shared by the dashboard's charts

library(ggplot2)

INK <- "#1d1c1a"
INK_2 <- "#57554f"
GRID <- "#e6e3dc"

theme_dash <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(colour = GRID, linewidth = 0.4),
      axis.title = element_text(colour = INK_2, size = rel(0.9)),
      axis.text = element_text(colour = INK_2),
      strip.text = element_text(colour = INK, face = "bold", hjust = 0),
      legend.position = "bottom",
      legend.title = element_text(colour = INK_2, size = rel(0.9)),
      plot.title.position = "plot",
      plot.caption = element_text(colour = INK_2, hjust = 0, size = rel(0.8))
    )
}

fmt <- function(x, digits = 1) {
  ifelse(is.finite(x), formatC(x, format = "f", digits = digits, big.mark = ","), "–")
}

# the numeric summary used across the app (and in the codebook)
num_summary <- function(x) {
  n_na <- sum(!is.finite(x))
  x <- x[is.finite(x)]
  q <- if (length(x)) quantile(x, c(0, .25, .5, .75, 1), names = FALSE) else rep(NA_real_, 5)
  tibble::tibble(
    n = length(x), missing = n_na,
    mean = if (length(x)) mean(x) else NA_real_,
    sd = if (length(x) > 1) sd(x) else NA_real_,
    min = q[1], q1 = q[2], median = q[3], q3 = q[4], max = q[5]
  )
}

# histogram counts per group on SHARED breaks, so rows are comparable
binned <- function(df, var, group, bins = 30, as_share = FALSE) {
  x <- df[[var]]
  rng <- range(x, na.rm = TRUE)
  if (!all(is.finite(rng))) return(NULL)
  if (diff(rng) == 0) rng <- rng + c(-0.5, 0.5)
  br <- seq(rng[1], rng[2], length.out = bins + 1)
  df |>
    dplyr::filter(is.finite(.data[[var]])) |>
    dplyr::mutate(bin = cut(.data[[var]], br, include.lowest = TRUE, labels = FALSE)) |>
    dplyr::count(group = .data[[group]], bin, name = "n") |>
    tidyr::complete(group, bin = seq_len(bins), fill = list(n = 0)) |>
    dplyr::group_by(group) |>
    dplyr::mutate(
      share = 100 * n / sum(n),
      y = if (as_share) share else n,
      x = br[bin] + diff(br)[1] / 2,
      lo = br[bin], hi = br[bin + 1]
    ) |>
    dplyr::ungroup()
}

# binned means of y along x (equal-count bins), per group
binned_means <- function(df, x, y, group, nbins = 10, min_n = 40) {
  df |>
    dplyr::filter(is.finite(.data[[x]]), is.finite(.data[[y]])) |>
    dplyr::group_by(group = .data[[group]]) |>
    dplyr::filter(dplyr::n() >= min_n) |>
    dplyr::mutate(bin = dplyr::ntile(.data[[x]], nbins)) |>
    dplyr::group_by(group, bin) |>
    dplyr::summarise(x = mean(.data[[x]]), y = mean(.data[[y]]), n = dplyr::n(), .groups = "drop")
}
