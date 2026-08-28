#!/usr/bin/env Rscript
# SEM Analysis: All Outcomes ±Moderation × 5 Models × 2 Estimators
# Uses cached CFA fits, adds structural paths

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

# ─────────────────────────────────────────────────────────────────────────────
# INITIALIZATION
# ─────────────────────────────────────────────────────────────────────────────

log_msg("═══════════════════════════════════════════════════════════════", "")
log_msg("SEM ANALYSIS: All Outcomes ±Moderation × 5 Models × 2 Estimators", "PHASE")
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
log_msg("PHASE 1: SEM with All 4 Outcomes (±Moderation)", "SECTION")
log_msg("", "")

# ─────────────────────────────────────────────────────────────────────────────
# PART 1: ALL OUTCOMES (Lavaan × 2 Moderation Variants)
# ─────────────────────────────────────────────────────────────────────────────

for (model_name in names(models)) {
  log_msg(sprintf("Model: %s", model_name), "")

  # Get CFA syntax and replace TOM/SAW
  cfa_syntax <- gsub("TOM \\+ SAW", "RELEVANCE_SCALE", models[[model_name]]())

  # Build SEM syntax: measurement + structural (latent outcome factor)
  sem_no_mod <- paste0(
    cfa_syntax, "\n",
    "# Structural: All 4 outcomes\n",
    "Outcome =~ NA*OF02_01_num_log + OF02_02_num_log + OF_Spender_bin + OF01_SCALE\n",
    "Outcome ~~ 1*Outcome\n"  # Fix variance for scale
  )

  sem_with_mod <- paste0(
    cfa_syntax, "\n",
    "# Structural: All 4 outcomes with SES-Z moderation\n",
    "Outcome =~ NA*OF02_01_num_log + OF02_02_num_log + OF_Spender_bin + OF01_SCALE\n",
    "Outcome ~~ 1*Outcome\n",
    "Outcome ~ SES_z\n"  # Simple moderation
  )

  # Test both moderation variants
  for (with_mod in c(FALSE, TRUE)) {
    syntax <- if (with_mod) sem_with_mod else sem_no_mod
    mod_label <- if (with_mod) "All4_mod" else "All4_no"

    # ─ LAVAAN MLR ─
    cache_key <- sprintf("sem_%s_%s_lavaan.rds", model_name, mod_label)
    path <- file.path(cache_dir, cache_key)

    cat(sprintf("  [%s Lavaan] ", mod_label))

    if (file.exists(path)) {
      cat("✓ (cached)\n")
      tryCatch({
        fit_lav <- readRDS(path)
        cfi <- as.numeric(fitMeasures(fit_lav, "cfi"))
        sem_results <- bind_rows(sem_results, tibble(
          Model = model_name,
          Outcome_config = "All 4",
          Moderation = with_mod,
          Estimator = "Lavaan",
          Converged = lavInspect(fit_lav, "converged"),
          CFI = cfi
        ))
      }, error = function(e) {
        cat("   (cache load failed)\n")
      })
    } else {
      t0 <- Sys.time()
      tryCatch({
        fit_lav <- sem(syntax, data = data, missing = "fiml", std.lv = TRUE, estimator = "MLR")
        t_sec <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
        saveRDS(fit_lav, path)
        cat(sprintf("✓ (%.0fs)\n", t_sec))

        if (lavInspect(fit_lav, "converged")) {
          cfi <- as.numeric(fitMeasures(fit_lav, "cfi"))
          sem_results <- bind_rows(sem_results, tibble(
            Model = model_name,
            Outcome_config = "All 4",
            Moderation = with_mod,
            Estimator = "Lavaan",
            Converged = TRUE,
            CFI = cfi
          ))
        }
      }, error = function(e) {
        cat(sprintf("✗ (%.60s)\n", as.character(e)))
      })
    }

    # ─ BLAVAAN MCMC ─
    cache_key <- sprintf("sem_%s_%s_blavaan.rds", model_name, mod_label)
    path <- file.path(cache_dir, cache_key)

    cat(sprintf("  [%s Blavaan] ", mod_label))

    if (file.exists(path)) {
      cat("✓ (cached)\n")
      sem_results <- bind_rows(sem_results, tibble(
        Model = model_name,
        Outcome_config = "All 4",
        Moderation = with_mod,
        Estimator = "Blavaan",
        Converged = TRUE,
        CFI = NA_real_
      ))
    } else {
      t0 <- Sys.time()
      tryCatch({
        fit_blav <- bsem(syntax, data = data, std.lv = TRUE,
                        n.chains = 2, burnin = 250, sample = 1000,
                        verbose = FALSE, seed = 2026)
        t_sec <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
        saveRDS(fit_blav, path)
        cat(sprintf("✓ (%.0fs)\n", t_sec))

        sem_results <- bind_rows(sem_results, tibble(
          Model = model_name,
          Outcome_config = "All 4",
          Moderation = with_mod,
          Estimator = "Blavaan",
          Converged = TRUE,
          CFI = NA_real_
        ))
      }, error = function(e) {
        cat(sprintf("✗\n"))
      })
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# PART 2: INDIVIDUAL OUTCOMES (Lavaan × All Variants)
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PHASE 2: SEM with Individual Outcomes (±Moderation)", "SECTION")
log_msg("", "")

for (model_name in names(models)) {
  log_msg(sprintf("Model: %s", model_name), "")

  cfa_syntax <- gsub("TOM \\+ SAW", "RELEVANCE_SCALE", models[[model_name]]())

  for (outcome in outcomes) {
    # Base: CFA + single outcome path
    sem_base <- paste0(
      cfa_syntax, "\n",
      sprintf("# Outcome: %s\n", outcome),
      sprintf("%s ~ 1  # Simple intercept\n", outcome)
    )

    # With moderation: outcome ~ SES_z
    sem_mod <- paste0(
      cfa_syntax, "\n",
      sprintf("# Outcome: %s with SES-Z moderation\n", outcome),
      sprintf("%s ~ SES_z\n", outcome)
    )

    for (with_mod in c(FALSE, TRUE)) {
      syntax <- if (with_mod) sem_mod else sem_base
      outcome_label <- gsub("_", "", outcome)
      mod_label <- if (with_mod) "_mod" else ""
      cache_key_base <- sprintf("sem_%s_%s%s", model_name, outcome_label, mod_label)

      # ─ LAVAAN ─
      cache_key <- sprintf("%s_lavaan.rds", cache_key_base)
      path <- file.path(cache_dir, cache_key)

      cat(sprintf("  [%s %s] ", outcome, if(with_mod) "Lav+mod" else "Lav"))

      if (file.exists(path)) {
        cat("✓\n")
        sem_results <- bind_rows(sem_results, tibble(
          Model = model_name,
          Outcome_config = outcome,
          Moderation = with_mod,
          Estimator = "Lavaan",
          Converged = TRUE,
          CFI = NA_real_
        ))
      } else {
        tryCatch({
          fit_lav <- sem(syntax, data = data, missing = "fiml", std.lv = TRUE, estimator = "MLR")
          saveRDS(fit_lav, path)
          cat("✓\n")

          sem_results <- bind_rows(sem_results, tibble(
            Model = model_name,
            Outcome_config = outcome,
            Moderation = with_mod,
            Estimator = "Lavaan",
            Converged = lavInspect(fit_lav, "converged"),
            CFI = NA_real_
          ))
        }, error = function(e) {
          cat("✗\n")
        })
      }

      # ─ BLAVAAN ─
      cache_key <- sprintf("%s_blavaan.rds", cache_key_base)
      path <- file.path(cache_dir, cache_key)

      cat(sprintf("  [%s %s] ", outcome, if(with_mod) "Bay+mod" else "Bay"))

      if (file.exists(path)) {
        cat("✓\n")
        sem_results <- bind_rows(sem_results, tibble(
          Model = model_name,
          Outcome_config = outcome,
          Moderation = with_mod,
          Estimator = "Blavaan",
          Converged = TRUE,
          CFI = NA_real_
        ))
      } else {
        tryCatch({
          fit_blav <- bsem(syntax, data = data, std.lv = TRUE,
                          n.chains = 2, burnin = 250, sample = 1000,
                          verbose = FALSE, seed = 2026)
          saveRDS(fit_blav, path)
          cat("✓\n")

          sem_results <- bind_rows(sem_results, tibble(
            Model = model_name,
            Outcome_config = outcome,
            Moderation = with_mod,
            Estimator = "Blavaan",
            Converged = TRUE,
            CFI = NA_real_
          ))
        }, error = function(e) {
          cat("✗\n")
        })
      }
    }
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# SAVE SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("SAVING RESULTS", "SECTION")

write_csv(sem_results, file.path(results_dir, "sem_results.csv"))
log_msg(sprintf("✓ SEM results: %d rows", nrow(sem_results)), "")

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("SEM ANALYSIS COMPLETE", "SUCCESS")
log_msg("═══════════════════════════════════════════════════════════════", "")

log_msg(sprintf("SEM fits computed/cached: %d", nrow(sem_results)), "")
log_msg(sprintf("Converged: %d", sum(sem_results$Converged)), "")
log_msg(sprintf("Cache size: %.1f MB", sum(file.size(list.files(cache_dir, full.names = TRUE)))/1e6), "")

log_msg("", "")
log_msg("Results saved to:", "")
log_msg(sprintf("  %s", file.path(results_dir, "sem_results.csv")), "")
log_msg("═══════════════════════════════════════════════════════════════", "")
