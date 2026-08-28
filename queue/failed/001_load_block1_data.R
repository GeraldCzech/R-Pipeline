#!/usr/bin/env Rscript
message("[", Sys.time(), "] 001: Loading Block 1 survey data...")

library(tidyverse)

results_dir <- file.path(dirname(getwd()), "results")
dir.create(results_dir, showWarnings = FALSE)

data_file <- "/home/gerald/10787172/fragebogen_cache_v5.rds"
if (!file.exists(data_file)) {
  stop("Data file not found: ", data_file)
}

block1_data <- readRDS(data_file)
message("  ✓ Loaded: ", nrow(block1_data), " respondents")
message("  ✓ Variables: ", ncol(block1_data))

saveRDS(block1_data, file.path(results_dir, "block1_data.rds"))
message("[", Sys.time(), "] ✅ Complete")
