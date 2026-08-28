#!/usr/bin/env Rscript
message("[", Sys.time(), "] 003: Loading evidence corpus...")

library(tidyverse)

results_dir <- file.path(dirname(getwd()), "results")
data_file <- "/home/gerald/dissertation/output/fragebogen.rds"

if (!file.exists(data_file)) {
  stop("Data file not found: ", data_file)
}

evid_corpus <- readRDS(data_file)
message("  ✓ Loaded: ", nrow(evid_corpus), " records")

saveRDS(evid_corpus, file.path(results_dir, "evid_corpus.rds"))
message("[", Sys.time(), "] ✅ Complete")
