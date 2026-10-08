# GOAL: for every submitted .Rmd, check whether the code runs and count lints
#
# For each .Rmd in `submissions_dir` this script
#   1. extracts the R code with knitr::purl() and sources it in a fresh R
#      session (so one student's objects/packages can't leak into the next),
#   2. runs lintr::lint() on the .Rmd, i.e. the same check as
#      lint(rstudioapi::getSourceEditorContext()$path) on the open file,
# and returns one table: file, whether the code ran, the error, n of lints.

suppressPackageStartupMessages(library(dplyr))

# Settings ----
submissions_dir <- "~/submissions_dv1/" # folder with the students' .Rmd files
timeout_sec <- 300 # give up on a file after this many seconds
output_csv <- file.path(submissions_dir, "code_and_lintr_check.csv")

# Run one .Rmd ----
# Returns NA if the code ran, otherwise the error message.
run_rmd <- function(rmd_path) {
  r_script <- tempfile(fileext = ".R")
  on.exit(unlink(r_script))

  purl_error <- tryCatch(
    {
      knitr::purl(rmd_path, output = r_script, documentation = 0, quiet = TRUE)
      NA_character_
    },
    error = function(e) paste("Could not extract code:", conditionMessage(e))
  )
  if (!is.na(purl_error)) {
    return(purl_error)
  }

  error <- tryCatch(
    callr::r(
      function(script, wd) {
        setwd(wd) # relative paths resolve from the .Rmd's own folder
        grDevices::pdf(NULL) # don't write Rplots.pdf next to the submissions
        last_warning <- NULL
        tryCatch(
          {
            withCallingHandlers(
              source(script, local = new.env()),
              warning = function(w) last_warning <<- conditionMessage(w)
            )
            NA_character_
          },
          # e.g. "cannot open the connection" only names the file in a warning
          error = function(e) {
            paste(c(conditionMessage(e), last_warning), collapse = " | ")
          }
        )
      },
      args = list(script = r_script, wd = dirname(rmd_path)),
      timeout = timeout_sec
    ),
    # R session crashed or timed out
    error = function(e) paste("R session failed:", conditionMessage(e))
  )
  # show the student's file name instead of the temporary script path
  gsub(r_script, basename(rmd_path), error, fixed = TRUE)
}

# Count lints in one .Rmd ----
count_lints <- function(rmd_path) {
  tryCatch(
    length(lintr::lint(rmd_path)),
    error = function(e) NA_integer_
  )
}

# Check all submissions ----
files <- list.files(
  submissions_dir,
  pattern = "\\.rmd$",
  ignore.case = TRUE,
  full.names = TRUE
)

results <- lapply(files, function(f) {
  message("Checking ", basename(f))
  error <- run_rmd(f)
  data.frame(
    file = basename(f),
    code_runs = is.na(error),
    error = error,
    n_lints = count_lints(f)
  )
}) |>
  bind_rows()

print(results, right = FALSE)
write.csv(results, output_csv, row.names = FALSE)
message("Saved to ", output_csv)
