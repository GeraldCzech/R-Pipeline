library(tidyverse)

data <- readRDS("pipeline_data_fc_bo.rds")

required_vars <- c("FC03_01", "FC03_02", "FC03_03", "TOM", "SAW")

cat("Checking for required Boenigk/Faircloth hierarchy variables:\n")
cat("═════════════════════════════════════════════════════════════\n\n")

for (v in required_vars) {
  exists <- v %in% colnames(data)
  if (exists) {
    n_vals <- sum(!is.na(data[[v]]))
    cat(sprintf("✓ %s: present (%d/%d = %.1f%%)\n", v, n_vals, nrow(data), 100*n_vals/nrow(data)))
  } else {
    cat(sprintf("✗ %s: MISSING\n", v))
  }
}
