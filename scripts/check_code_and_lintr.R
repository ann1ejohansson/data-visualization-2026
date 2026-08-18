# GOAL: check if students' code runs (0.5pt) and is lintr proof (0.5pt)

# Find submissions
path = "~/submissions_dv1/" # folder that contains submission files
files = list.files(path)

# Function for testing if code runs
testscript <- function(scriptpath) {
  tryCatch({
    # Tests if the script runs without error
    ext = tolower(tools::file_ext(scriptpath))
    if (ext == 'r'){
      source(scriptpath, local = new.env())
    }
    else if (ext =='rmd'){
      rmarkdown::render(scriptpath)
    }
    return(0.5)
  },
  error = function(cond){
    message('Script not OK')
    return(0)
  })}

# Prepare output
names = c()
ids = c()
lintr = c()
points = c()

# Check per student if code runs and lintr style
for (file in files) {
  # remove underscore from filename
  fn_split  = strsplit(file, '_')[[1]]
  
  # checks if code runs
  points = c(points, testscript(paste0(path, file)))

  # count number of lintr errors
  lintr = c(lintr, length(oefenwebTools::lintrProfile(paste0(path, file))))

  # get student name and id number
  names = c(names, fn_split[1])
  ids = c(ids, fn_split[3])
}

# combine output to one df
df = data.frame('name' = names,
                'id' = ids,
                'n__linter_errors' = lintr,
                'code_runs' = points)
df <- df %>%
  mutate(lintr_proof = ifelse(n__linter_errors == 0, 0.5, 0),
         total_points = lintr_proof + code_runs)
df

write.csv(df, paste0(getwd(), "/DV1_code_lintr_checked.csv"))
