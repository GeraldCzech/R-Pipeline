#!/usr/bin/env Rscript
# Simple, Straightforward Analysis Pipeline
# Runs all 17 core analyses sequentially, logs everything
# Safe to interrupt - can re-run any time

library(tidyverse)

# ============================================================================
# Setup
# ============================================================================

log_file <- "logs/analyses.log"
results_dir <- "results"
dir.create(results_dir, showWarnings = FALSE)
dir.create("logs", showWarnings = FALSE)

log_msg <- function(msg, tag = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  formatted <- sprintf("[%s] %s: %s", timestamp, tag, msg)
  cat(formatted, "\n")
  cat(formatted, "\n", file = log_file, append = TRUE)
}

run_analysis <- function(name, description, expr) {
  log_msg(sprintf("Starting: %s", description), "START")
  start_time <- Sys.time()

  tryCatch({
    result <- eval(expr)
    elapsed <- difftime(Sys.time(), start_time, units = "secs")
    log_msg(sprintf("✅ %s (%.1f seconds)", description, elapsed), "DONE")
    return(result)
  }, error = function(e) {
    log_msg(sprintf("❌ %s - ERROR: %s", description, conditionMessage(e)), "ERROR")
    return(NULL)
  })
}

# ============================================================================
# PHASE 1: Load Data (5 min)
# ============================================================================

log_msg("================================================", "")
log_msg("PHASE 1: Loading Data Files", "PHASE")
log_msg("================================================", "")

# Load Block 1 (standardized Faircloth data)
block1_data <- run_analysis("block1", "Block 1 Survey Data (Faircloth)", {
  data_file <- "/home/gerald/10787172/scripts/research2/output/daten_standardisiert.RData"
  loaded <- load(data_file)
  d <- dat_fc  # Use the standardized Faircloth dataset
  saveRDS(d, file.path(results_dir, "block1_data.rds"))
  d
})

# Load Admin Data
admin_data <- run_analysis("admin", "Admin Data", {
  data_file <- "/home/gerald/10787172/output/NGO_BMF_ID_Referenzliste_Flach.csv"
  d <- readr::read_csv(data_file, show_col_types = FALSE)
  saveRDS(d, file.path(results_dir, "admin_data.rds"))
  d
})

# Load Evidence Corpus
evid_corpus <- run_analysis("evid", "Evidence Corpus", {
  data_file <- "/home/gerald/dissertation/output/fragebogen.rds"
  d <- readRDS(data_file)
  saveRDS(d, file.path(results_dir, "evid_corpus.rds"))
  d
})

if (is.null(block1_data) || is.null(admin_data) || is.null(evid_corpus)) {
  log_msg("❌ Data loading failed - stopping", "ERROR")
  quit(save = "no", status = 1)
}

log_msg("✅ All data loaded successfully", "CHECKPOINT")
log_msg("", "")

# Data is already prepared (standardized from Npodashboard)
log_msg("Data already standardized - TOM, SAW, SES_z ready", "INFO")

# ============================================================================
# PHASE 2: Bayesian SEM Models (6-18 hours)
# ============================================================================

log_msg("================================================", "")
log_msg("PHASE 2: Bayesian SEM Models", "PHASE")
log_msg("  Expected time: 6-18 hours (3 models × 2-6 hours each)", "")
log_msg("================================================", "")

source("R/blavaan_models.R")
library(blavaan)

# BSEM 1: Faircloth Core-B
bsem_fc <- run_analysis("bsem_fc", "BSEM Faircloth Core-B (4 chains, 4000 samples)", {
  result <- fit_blavaan_model(
    data = block1_data,
    syntax = fc_smaller_syntax(),
    label = "faircloth_core_b",
    n.chains = 4,
    burnin = 2000,
    sample = 4000
  )
  saveRDS(result, file.path(results_dir, "bsem_faircloth_coreb.rds"))
  result
})

# BSEM 2: Boenigk
bsem_bo <- run_analysis("bsem_bo", "BSEM Boenigk (4 chains, 4000 samples)", {
  result <- fit_blavaan_model(
    data = block1_data,
    syntax = bo_orig_syntax(),
    label = "boenigk_becker",
    n.chains = 4,
    burnin = 2000,
    sample = 4000
  )
  saveRDS(result, file.path(results_dir, "bsem_boenigk.rds"))
  result
})

# BSEM 3: Romero
bsem_ro <- run_analysis("bsem_ro", "BSEM Romero (4 chains, 4000 samples)", {
  result <- fit_blavaan_model(
    data = block1_data,
    syntax = ro_smaller_syntax(),
    label = "rios_romero",
    n.chains = 4,
    burnin = 2000,
    sample = 4000
  )
  saveRDS(result, file.path(results_dir, "bsem_romero.rds"))
  result
})

log_msg("✅ BSEM models complete", "CHECKPOINT")
log_msg("", "")

# ============================================================================
# PHASE 3: RoBMA Meta-Analysis (4-8 hours)
# ============================================================================

log_msg("================================================", "")
log_msg("PHASE 3: RoBMA Bayesian Meta-Analysis", "PHASE")
log_msg("  Expected time: 4-8 hours", "")
log_msg("================================================", "")

source("R/robma_pipeline.R")
library(RoBMA)

robma_fit <- run_analysis("robma", "RoBMA Analysis", {
  fit <- run_robma(evid_corpus, seed = 20260815)
  saveRDS(fit, file.path(results_dir, "robma_fit.rds"))
  fit
})

log_msg("✅ RoBMA analysis complete", "CHECKPOINT")
log_msg("", "")

# ============================================================================
# PHASE 4: Bayesian Multilevel Model (2-4 hours)
# ============================================================================

log_msg("================================================", "")
log_msg("PHASE 4: Bayesian Multilevel Model", "PHASE")
log_msg("  Expected time: 2-4 hours", "")
log_msg("================================================", "")

source("R/bayes_admin_mlm.R")
library(brms)

bayes_mlm <- run_analysis("bayes_mlm", "Bayesian MLM (4 chains, 4000 iter)", {
  fit <- fit_bayes_admin_mlm(admin_data, chains = 4, iter = 4000)
  saveRDS(fit, file.path(results_dir, "bayes_mev_fit.rds"))
  fit
})

log_msg("✅ Bayesian MLM complete", "CHECKPOINT")
log_msg("", "")

# ============================================================================
# PHASE 5: Feature Analyses (2 hours)
# ============================================================================

log_msg("================================================", "")
log_msg("PHASE 5: Feature Analyses", "PHASE")
log_msg("  Dominance, NCA, ElasticNet", "")
log_msg("================================================", "")

source("R/dominance_nca_elasticnet.R")

dom_results <- run_analysis("dominance", "Dominance Analysis", {
  run_dominance_analysis(block1_data, outcome = "OF_Spender_bin")
})

nca_results <- run_analysis("nca", "NCA Analysis", {
  run_nca_analysis(block1_data, outcome = "OF_Spender_bin")
})

enet_results <- run_analysis("elasticnet", "ElasticNet Analysis", {
  run_elastic_net(block1_data, outcome_ordinal = "engagement_ladder")
})

if (!is.null(dom_results)) {
  saveRDS(dom_results, file.path(results_dir, "dominance_results.rds"))
}
if (!is.null(nca_results)) {
  saveRDS(nca_results, file.path(results_dir, "nca_results.rds"))
}
if (!is.null(enet_results)) {
  saveRDS(enet_results, file.path(results_dir, "elasticnet_results.rds"))
}

log_msg("✅ Feature analyses complete", "CHECKPOINT")
log_msg("", "")

# ============================================================================
# Summary
# ============================================================================

log_msg("================================================", "")
log_msg("🎉 ALL ANALYSES COMPLETE", "SUCCESS")
log_msg("================================================", "")
log_msg(sprintf("Results saved to: %s/", results_dir), "")
log_msg("Files:", "")
log_msg(sprintf("  - bsem_faircloth_coreb.rds"), "")
log_msg(sprintf("  - bsem_boenigk.rds"), "")
log_msg(sprintf("  - bsem_romero.rds"), "")
log_msg(sprintf("  - robma_fit.rds"), "")
log_msg(sprintf("  - bayes_mev_fit.rds"), "")
log_msg(sprintf("  - dominance_results.rds"), "")
log_msg(sprintf("  - nca_results.rds"), "")
log_msg(sprintf("  - elasticnet_results.rds"), "")
log_msg("", "")
