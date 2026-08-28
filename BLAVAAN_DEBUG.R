#!/usr/bin/env Rscript
# Debug Blavaan SEM failures

suppressPackageStartupMessages({
  library(lavaan)
  library(blavaan)
  library(tidyverse)
})

log_msg <- function(msg) {
  cat(sprintf("[%s] %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), msg))
}

log_msg("═══════════════════════════════════════════════════════════════")
log_msg("BLAVAAN DIAGNOSTIC TEST")
log_msg("═══════════════════════════════════════════════════════════════")

# Load data
data <- readRDS("/home/gerald/R-pipeline/results/block1_prepared.rds")
source("/home/gerald/Npodashboard/R/12_lavaan_models.R")

log_msg("Data loaded: n=2038")
log_msg("")

# Test 1: Simple CFA with Blavaan
log_msg("TEST 1: Simple CFA with Blavaan (fc_core_B)")

fc_core_b_syntax <- gsub("TOM \\+ SAW", "RELEVANCE_SCALE", CFA_REGISTRY$fc_core_B$fun())

log_msg("Attempting bcfa()...")
tryCatch({
  fit_cfa <- bcfa(fc_core_b_syntax,
                 data = data,
                 missing = "fiml",
                 std.lv = TRUE,
                 n.chains = 2,
                 n.iter = 500,
                 n.burnin = 100,
                 verbose = FALSE,
                 seed = 2026)
  log_msg("✓ CFA SUCCESS")
}, error = function(e) {
  log_msg(sprintf("✗ CFA ERROR: %s", as.character(e)))
})

log_msg("")

# Test 2: SEM with all outcomes (no moderation)
log_msg("TEST 2: SEM with All 4 Outcomes (no moderation)")

sem_syntax <- paste0(
  fc_core_b_syntax, "\n",
  "Outcome =~ NA*OF02_01_num_log + OF02_02_num_log + OF_Spender_bin + OF01_SCALE\n",
  "Outcome ~~ 1*Outcome\n"
)

log_msg("Attempting bsem() with simpler settings...")
log_msg("  n.chains: 1 (simplified)")
log_msg("  n.iter: 200 (minimal)")
log_msg("  n.burnin: 50")

tryCatch({
  fit_sem <- bsem(sem_syntax,
                 data = data,
                 missing = "fiml",
                 std.lv = TRUE,
                 n.chains = 1,     # Reduced from 2
                 n.iter = 200,      # Reduced from 1000
                 n.burnin = 50,     # Reduced from 250
                 verbose = FALSE,
                 seed = 2026)
  log_msg("✓ SEM SUCCESS (simplified settings)")
}, error = function(e) {
  err_msg <- as.character(e)
  log_msg(sprintf("✗ SEM ERROR: %s", substring(err_msg, 1, 200)))
  log_msg("")
  log_msg("FULL ERROR:")
  log_msg(err_msg)
})

log_msg("")

# Test 3: Check blavaan version & settings
log_msg("TEST 3: Environment & Package Info")
log_msg(sprintf("  lavaan version: %s", packageVersion("lavaan")))
log_msg(sprintf("  blavaan version: %s", packageVersion("blavaan")))
log_msg(sprintf("  R version: %s", R.version$version.string))

# Test 4: Try with different MCMC settings
log_msg("")
log_msg("TEST 4: Alternative MCMC Settings")

log_msg("Attempting with n.chains=1, shorter chain...")
tryCatch({
  fit_alt <- bsem(sem_syntax,
                 data = data,
                 missing = "fiml",
                 std.lv = TRUE,
                 n.chains = 1,
                 n.iter = 100,
                 n.burnin = 25,
                 verbose = TRUE,   # Show output
                 seed = 2026)
  log_msg("✓ ALTERNATIVE SETTINGS WORKED")
}, error = function(e) {
  log_msg(sprintf("✗ Still fails: %s", substring(as.character(e), 1, 100)))
})

log_msg("")
log_msg("═══════════════════════════════════════════════════════════════")
log_msg("DIAGNOSTIC COMPLETE")
log_msg("═══════════════════════════════════════════════════════════════")
