library(tidyverse)

data_raw <- readRDS("pipeline_data_fc_bo.rds")

# Get all variable names
all_vars <- colnames(data_raw)

cat("All variables containing 'BA':\n")
ba_vars <- all_vars %>% keep(~str_starts(., "BA"))
print(ba_vars)

cat("\n\nActual numeric BA items (that could be Likert scale):\n")
for (v in ba_vars) {
  cls <- class(data_raw[[v]])[1]
  if (cls %in% c("numeric", "avector", "ordered", "factor")) {
    if (cls %in% c("numeric", "ordered", "factor")) {
      unique_vals <- unique(na.omit(data_raw[[v]]))
      cat(sprintf("%s (%s): %s\n", v, cls, paste(sort(unique_vals), collapse=", ")))
    } else if (cls == "avector") {
      unique_vals <- unique(na.omit(data_raw[[v]]))
      if (is.numeric(unique_vals) || length(unique_vals) < 10) {
        cat(sprintf("%s (avector): %s\n", v, paste(sort(unique_vals), collapse=", ")))
      } else {
        cat(sprintf("%s (avector, character): %d unique values (organization names?)\n", v, length(unique_vals)))
      }
    }
  }
}

cat("\n\nAll numeric-like variables starting with B:\n")
b_vars <- all_vars %>% keep(~str_starts(., "B") & str_length(.) <= 6)
for (v in b_vars) {
  cls <- class(data_raw[[v]])[1]
  n_vals <- sum(!is.na(data_raw[[v]]))
  cat(sprintf("%-12s %-10s n=%4d\n", v, cls, n_vals))
}
