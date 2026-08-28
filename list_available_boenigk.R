library(tidyverse)

data <- readRDS("pipeline_data_fc_bo.rds")

cat("All variables in FC_BO data:\n")
cat("═════════════════════════════════════════════════════════\n\n")

vars <- colnames(data)

# Group by prefix
prefixes <- sapply(strsplit(vars, "_"), function(x) x[1]) %>% unique() %>% sort()

for (prefix in prefixes) {
  matching <- vars[startsWith(vars, prefix)]
  cat(sprintf("%s: %d variables\n", prefix, length(matching)))
  cat(sprintf("  %s\n", paste(matching, collapse=", ")))
  cat("\n")
}

cat("\nBoenigk-related variables (B* and BO*):\n")
b_vars <- vars[startsWith(vars, "B")]
for (v in b_vars) {
  cls <- class(data[[v]])[1]
  n_vals <- sum(!is.na(data[[v]]))
  cat(sprintf("  %s (%s, n=%d)\n", v, cls, n_vals))
}
