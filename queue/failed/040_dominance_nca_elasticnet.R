#!/usr/bin/env Rscript
message("[", Sys.time(), "] 040: Dominance, NCA, ElasticNet...")

library(tidyverse)

results_dir <- file.path(dirname(getwd()), "results")
block1_data <- readRDS(file.path(results_dir, "block1_data.rds"))
source("R/dominance_nca_elasticnet.R")

message("  ✓ Running feature analysis suite")

tryCatch({
  dom <- run_dominance_analysis(block1_data, outcome = "OF_Spender_bin")
  nca <- run_nca_analysis(block1_data, outcome = "OF_Spender_bin")
  enet <- run_elastic_net(block1_data, outcome_ordinal = "engagement_ladder")

  saveRDS(list(dominance = dom, nca = nca, elasticnet = enet),
          file.path(results_dir, "combined_analyses.rds"))
  message("[", Sys.time(), "] ✅ Complete")
}, error = function(e) {
  message("ERROR: ", conditionMessage(e))
  stop(e)
})
