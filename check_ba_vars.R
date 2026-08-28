library(tidyverse)

# Load raw data
data_raw <- readRDS("pipeline_data_fc_bo.rds")

# Check what variables actually exist
ba_vars <- colnames(data_raw) %>% 
  keep(function(x) str_starts(x, "BA"))

cat("Available BA variables:\n")
print(ba_vars)

cat("\nColumn classes:\n")
for (v in ba_vars) {
  cat(sprintf("%s: %s\n", v, class(data_raw[[v]])[1]))
}

# Check data completeness
cat("\nData completeness for available BA variables:\n")
for (v in ba_vars) {
  n_complete <- sum(!is.na(data_raw[[v]]))
  cat(sprintf("%s: %d/%d (%.1f%%)\n", v, n_complete, nrow(data_raw), 100*n_complete/nrow(data_raw)))
}
