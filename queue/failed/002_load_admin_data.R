#!/usr/bin/env Rscript
message("[", Sys.time(), "] 002: Loading admin data...")

library(tidyverse)

results_dir <- file.path(dirname(getwd()), "results")
data_file <- "/home/gerald/10787172/output/NGO_BMF_ID_Referenzliste_Flach.csv"

if (!file.exists(data_file)) {
  stop("Data file not found: ", data_file)
}

admin_data <- readr::read_csv(data_file, show_col_types = FALSE)
message("  ✓ Loaded: ", nrow(admin_data), " organizations")

saveRDS(admin_data, file.path(results_dir, "admin_data.rds"))
message("[", Sys.time(), "] ✅ Complete")
