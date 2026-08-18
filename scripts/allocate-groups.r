# ---------------------------
# Function: allocate_groups
# Rules: 
# - Groups are only size 2 or 3 
# - Split by RQ into groups of 3 
# - Special case: exactly 5 -> 2 + 3 
# - Special case: exactly 4 -> 2 + 2
# ---------------------------

allocate_groups <- function(data) {
  set.seed(NULL)  # randomize
  
  groups <- list()
  group_id <- 1
  
  # Split students by their RQ choice
  split_RQs <- split(data, data$RQ)
  
  for (proj in names(split_RQs)) {
    students <- split_RQs[[proj]]
    
    # Random shuffle
    students <- students[sample(nrow(students)), ]
    n <- nrow(students)
    
    # --- Handle small cases ---
    if (n == 1) {
      groups[[group_id]] <- students
      group_id <- group_id + 1
      next
    }
    if (n == 2) {
      groups[[group_id]] <- students
      group_id <- group_id + 1
      next
    }
    if (n == 4) {
      groups[[group_id]] <- students[1:2, ]
      group_id <- group_id + 1
      groups[[group_id]] <- students[3:4, ]
      group_id <- group_id + 1
      next
    }
    if (n == 5) {
      groups[[group_id]] <- students[1:2, ]
      group_id <- group_id + 1
      groups[[group_id]] <- students[3:5, ]
      group_id <- group_id + 1
      next
    }
    
    # --- Normal case ---
    full_groups <- n %/% 3   # how many full groups of 3
    leftover <- n %% 3       # 0, 1, or 2
    
    # Make groups of 3
    if (full_groups > 0) {
      for (i in 1:full_groups) {
        idx <- ((i - 1) * 3 + 1):(i * 3)
        groups[[group_id]] <- students[idx, ]
        group_id <- group_id + 1
      }
    }
    
    # Handle leftover (1 or 2)
    if (leftover == 1) {
      # Turn last 3 into a 2 + 2 split
      last_group <- groups[[group_id - 1]]
      groups[[group_id - 1]] <- last_group[1:2, ]
      groups[[group_id]] <- rbind(last_group[3, ], students[n, ])
      group_id <- group_id + 1
    } else if (leftover == 2) {
      idx <- (n - 1):n
      groups[[group_id]] <- students[idx, ]
      group_id <- group_id + 1
    }
  }
  
  return(groups)
}

# ---------------------------
# Data
# ---------------------------

# # Test
# set.seed(444)
# students <- data.frame(
#   Name = paste0("S", 1:35),
#   RQ = sample(paste0("RQ", 1:4), 35, replace = TRUE)
# )
# 
# # test with n < 3
# students[which(students$RQ == "RQ1"), "RQ"] <- "RQ2"
# students[1:2, "RQ"] <- "RQ1"

students <- read.csv("choose-rq.csv", header = TRUE)
names(students)[1] <- "Name"

# ---------------------------
# Allocate groups 
# ---------------------------
groups <- allocate_groups(students)

# Print results
for (i in seq_along(groups)) {
  cat("\nGroup", i, ":\n")
  print(groups[[i]])
}

# make into dataframe with group number
final_groups <- do.call(rbind, lapply(seq_along(groups), function(i) {
  df <- groups[[i]]
  df$Group <- i
  return(df)
}))

#remove row numbers
rownames(final_groups) <- NULL
print(final_groups)
table(final_groups$Group)
write.csv(final_groups, file = "final_groups.csv")

merged <- merge(students[, c("Name", "Github.username")], final_groups, by = c("Name"))
write.csv(merged, file = "final_groups_username.csv")
