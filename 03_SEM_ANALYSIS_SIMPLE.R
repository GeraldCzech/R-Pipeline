#!/usr/bin/env Rscript
# SEM Analysis: All Outcomes (NO SES-Z Moderation)
# Simpler & faster: Tests baseline structural relationships only

set.seed(2026)
suppressPackageStartupMessages({
  library(tidyverse)
  library(lavaan)
  library(blavaan)
})

log_msg <- function(msg, level = "INFO") {
  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] %s: %s\n", ts, level, msg))
  flush.console()
}

log_msg("═══════════════════════════════════════════════════════════════", "")
log_msg("SEM ANALYSIS - BASELINE (No SES-Z Moderation)", "PHASE")
log_msg("═══════════════════════════════════════════════════════════════", "")

data <- readRDS("/home/gerald/R-pipeline/results/block1_prepared.rds")
source("/home/gerald/Npodashboard/R/12_lavaan_models.R")

cache_dir <- "/home/gerald/R-pipeline/cache"
results_dir <- "/home/gerald/R-pipeline/results/summaries"
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

log_msg(sprintf("Data: n=%d | Cache: %s", nrow(data), cache_dir), "")

# Models & Outcomes
models <- list(
  fc_core_B = CFA_REGISTRY$fc_core_B$fun,
  fc_higher_order = CFA_REGISTRY$fc_higher_order_original$fun,
  fc_first_order = CFA_REGISTRY$fc_first_order_original$fun,
  bo_original = CFA_REGISTRY$bo_original$fun,
  bo_network = CFA_REGISTRY$bo_first_order_network$fun
)

outcomes <- c("OF02_01_num_log", "OF02_02_num_log", "OF_Spender_bin", "OF01_SCALE")
sem_results <- tibble()

log_msg("", "")
log_msg("PHASE 1: SEM with All 4 Outcomes (Baseline, No Moderation)", "SECTION")
log_msg("", "")

# ─ PART 1: ALL OUTCOMES (No Moderation) ─
for (model_name in names(models)) {
  log_msg(sprintf("Model: %s", model_name), "")
  
  cfa_syntax <- gsub("TOM \\+ SAW", "RELEVANCE_SCALE", models[[model_name]]())
  
  # Simple SEM: Just CFA + structural paths, NO SES-Z interaction
  sem_syntax <- paste0(
    cfa_syntax, "\n",
    "# Structural: All 4 outcomes (baseline)\n",
    "Outcome =~ NA*OF02_01_num_log + OF02_02_num_log + OF_Spender_bin + OF01_SCALE\n",
    "Outcome ~~ 1*Outcome\n"
  )
  
  mod_label <- "All4_baseline"
  
  # ─ LAVAAN MLR ─
  cache_key <- sprintf("sem_%s_%s_lavaan.rds", model_name, mod_label)
  path <- file.path(cache_dir, cache_key)
  
  cat(sprintf("  [Lavaan] "))
  
  if (file.exists(path)) {
    cat("✓ (cached)\n")
  } else {
    t0 <- Sys.time()
    tryCatch({
      fit_lav <- sem(sem_syntax, data = data, missing = "fiml", std.lv = TRUE, estimator = "MLR")
      t_sec <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
      saveRDS(fit_lav, path)
      cat(sprintf("✓ (%.0fs)\n", t_sec))
    }, error = function(e) {
      cat(sprintf("✗ (%.60s)\n", as.character(e)))
    })
  }
  
  # ─ BLAVAAN MCMC ─
  cache_key <- sprintf("sem_%s_%s_blavaan.rds", model_name, mod_label)
  path <- file.path(cache_dir, cache_key)
  
  cat(sprintf("  [Blavaan] "))
  
  if (file.exists(path)) {
    cat("✓ (cached)\n")
  } else {
    t0 <- Sys.time()
    tryCatch({
      fit_blav <- bsem(sem_syntax, data = data, std.lv = TRUE,
                      n.chains = 2, burnin = 250, sample = 1000,
                      verbose = FALSE, seed = 2026)
      t_sec <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
      saveRDS(fit_blav, path)
      cat(sprintf("✓ (%.0fs)\n", t_sec))
    }, error = function(e) {
      cat(sprintf("✗\n"))
    })
  }
}

log_msg("", "")
log_msg("PHASE 2: SEM with Individual Outcomes (Baseline)", "SECTION")
log_msg("", "")

# ─ PART 2: INDIVIDUAL OUTCOMES (No Moderation) ─
for (model_name in names(models)) {
  log_msg(sprintf("Model: %s", model_name), "")
  
  cfa_syntax <- gsub("TOM \\+ SAW", "RELEVANCE_SCALE", models[[model_name]]())
  
  for (outcome in outcomes) {
    sem_syntax <- paste0(
      cfa_syntax, "\n",
      sprintf("# Outcome: %s (baseline)\n", outcome),
      sprintf("%s ~ 1\n", outcome)
    )
    
    outcome_label <- gsub("_", "", outcome)
    cache_key_base <- sprintf("sem_%s_%s_baseline", model_name, outcome_label)
    
    # ─ LAVAAN ONLY ─
    cache_key <- sprintf("%s_lavaan.rds", cache_key_base)
    path <- file.path(cache_dir, cache_key)
    
    cat(sprintf("  [%s] ", outcome))
    
    if (file.exists(path)) {
      cat("✓\n")
    } else {
      tryCatch({
        fit_lav <- sem(sem_syntax, data = data, missing = "fiml", std.lv = TRUE, estimator = "MLR")
        saveRDS(fit_lav, path)
        cat("✓\n")
      }, error = function(e) {
        cat("✗\n")
      })
    }
  }
}

log_msg("", "")
log_msg("═══════════════════════════════════════════════════════════════", "")
log_msg("BASELINE SEM ANALYSIS COMPLETE", "SUCCESS")
log_msg("═══════════════════════════════════════════════════════════════", "")

# Summary
n_files <- length(list.files(cache_dir, pattern = "^sem_.*baseline.*\\.rds$"))
log_msg(sprintf("Baseline SEM fits: %d", n_files), "")
log_msg("Configuration: No SES-Z moderation (simpler, faster, more stable)", "INFO")

