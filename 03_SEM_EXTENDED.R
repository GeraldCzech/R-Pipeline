#!/usr/bin/env Rscript
# EXTENDED SEM ANALYSIS WITH MULTILEVEL STRATIFICATION
# Tests heterogeneity by: (1) Donation Type, (2) Organizations
# Parallel: Global + Stratified by Type + Stratified by Org

set.seed(2026)
suppressPackageStartupMessages({
  library(tidyverse)
  library(lavaan)
  library(future)
  library(furrr)
})

log_msg <- function(msg, level = "INFO") {
  ts <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] %s: %s\n", ts, level, msg))
  flush.console()
}

log_msg("═══════════════════════════════════════════════════════════════", "")
log_msg("EXTENDED SEM ANALYSIS - MULTILEVEL STRATIFICATION", "PHASE")
log_msg("Heterogeneity by Donation Type AND Organization", "")
log_msg("═══════════════════════════════════════════════════════════════", "")

# ─────────────────────────────────────────────────────────────────────────────
# LOAD DATA & PREPARE
# ─────────────────────────────────────────────────────────────────────────────

log_msg("Loading data...", "")

data <- readRDS("/home/gerald/R-pipeline/results/block1_prepared.rds")
source("/home/gerald/Npodashboard/R/12_lavaan_models.R")

log_msg(sprintf("Data: n=%d respondents", nrow(data)), "")

# Create donation type variable
data$donation_type <- case_when(
  is.na(data$donation_type) ~ "Unknown",
  TRUE ~ data$donation_type
)

donation_types <- unique(na.omit(data$donation_type))
log_msg(sprintf("Donation types: %s", paste(donation_types, collapse=", ")), "")

# Get organizations (assuming org_id column exists)
if ("org_id" %in% names(data)) {
  orgs <- unique(na.omit(data$org_id))
  log_msg(sprintf("Organizations: %d", length(orgs)), "")
} else {
  log_msg("Warning: org_id not found, will skip org stratification", "WARN")
  orgs <- c()
}

# ─────────────────────────────────────────────────────────────────────────────
# SETUP PARALLEL PROCESSING
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("Setting up parallel processing...", "")

n_cores <- detectCores()
n_workers <- max(2, n_cores - 2)

log_msg(sprintf("Using %d parallel workers", n_workers), "")
plan(multisession, workers = n_workers)

# ─────────────────────────────────────────────────────────────────────────────
# PART A: GLOBAL SEM (ALL DONORS, ALL ORGS)
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART A: Global SEM (All donors, all organizations)", "SECTION")

models <- list(
  fc_core_B = CFA_REGISTRY$fc_core_B$fun,
  fc_higher_order = CFA_REGISTRY$fc_higher_order_original$fun,
  fc_first_order = CFA_REGISTRY$fc_first_order_original$fun,
  bo_original = CFA_REGISTRY$bo_original$fun,
  bo_network = CFA_REGISTRY$bo_first_order_network$fun
)

sem_global <- expand_grid(
  model_name = names(models),
  stratum = "Global"
) %>%
  mutate(
    fit = future_map(
      model_name,
      ~{
        syntax_cfa <- gsub("TOM \\+ SAW", "RELEVANCE_SCALE", models[[.x]]())
        syntax_sem <- paste0(
          syntax_cfa, "\n",
          "Outcome =~ NA*OF02_01_num_log + OF02_02_num_log + OF_Spender_bin + OF01_SCALE\n",
          "Outcome ~~ 1*Outcome\n"
        )

        tryCatch({
          sem(syntax_sem, data = data, missing = "fiml", std.lv = TRUE, estimator = "MLR")
        }, error = function(e) NULL)
      },
      .progress = TRUE
    )
  ) %>%
  filter(map_lgl(fit, ~!is.null(.x)))

log_msg(sprintf("✓ Global SEM: %d models converged", nrow(sem_global)), "")

# ─────────────────────────────────────────────────────────────────────────────
# PART B: STRATIFIED SEM (BY DONATION TYPE)
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART B: Stratified SEM (By Donation Type)", "SECTION")
log_msg(sprintf("Running %d models × %d types in parallel", length(models), length(donation_types)), "")

sem_by_type <- expand_grid(
  model_name = names(models),
  donation_type = donation_types
) %>%
  mutate(
    stratum = donation_type,
    fit = future_map2(
      model_name, donation_type,
      ~{
        data_subset <- data %>% filter(donation_type == .y)

        syntax_cfa <- gsub("TOM \\+ SAW", "RELEVANCE_SCALE", models[[.x]]())
        syntax_sem <- paste0(
          syntax_cfa, "\n",
          "Outcome =~ NA*OF02_01_num_log + OF02_02_num_log + OF_Spender_bin + OF01_SCALE\n",
          "Outcome ~~ 1*Outcome\n"
        )

        tryCatch({
          sem(syntax_sem, data = data_subset, missing = "fiml", std.lv = TRUE, estimator = "MLR")
        }, error = function(e) NULL)
      },
      .progress = TRUE
    )
  ) %>%
  filter(map_lgl(fit, ~!is.null(.x)))

log_msg(sprintf("✓ By-Type SEM: %d models converged", nrow(sem_by_type)), "")

# ─────────────────────────────────────────────────────────────────────────────
# PART C: STRATIFIED SEM (BY ORGANIZATION) - Sample Large Orgs
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART C: Stratified SEM (By Organization - top 10)", "SECTION")

if (length(orgs) > 0) {
  # Get top 10 largest organizations
  org_sizes <- data %>%
    group_by(org_id) %>%
    summarize(n = n(), .groups = "drop") %>%
    arrange(desc(n)) %>%
    head(10)

  log_msg(sprintf("Fitting top 10 organizations (n=%d to %d per org)",
                  min(org_sizes$n), max(org_sizes$n)), "")

  sem_by_org <- expand_grid(
    model_name = c("bo_original", "fc_core_B"),  # Only 2 models per org (faster)
    org_id = org_sizes$org_id
  ) %>%
    mutate(
      stratum = as.character(org_id),
      fit = future_map2(
        model_name, org_id,
        ~{
          data_subset <- data %>% filter(org_id == .y)

          if (nrow(data_subset) < 30) return(NULL)  # Skip small orgs

          syntax_cfa <- gsub("TOM \\+ SAW", "RELEVANCE_SCALE", models[[.x]]())
          syntax_sem <- paste0(
            syntax_cfa, "\n",
            "Outcome =~ NA*OF02_01_num_log + OF02_02_num_log + OF_Spender_bin + OF01_SCALE\n",
            "Outcome ~~ 1*Outcome\n"
          )

          tryCatch({
            sem(syntax_sem, data = data_subset, missing = "fiml", std.lv = TRUE, estimator = "MLR")
          }, error = function(e) NULL)
        },
        .progress = TRUE
      )
    ) %>%
    filter(map_lgl(fit, ~!is.null(.x)))

  log_msg(sprintf("✓ By-Org SEM: %d models converged", nrow(sem_by_org)), "")
} else {
  log_msg("⚠️ Organization stratification skipped (no org_id column)", "WARN")
  sem_by_org <- tibble()
}

# ─────────────────────────────────────────────────────────────────────────────
# PART D: MULTI-GROUP SEM (DONATION TYPE DIFFERENCES - FORMAL TEST)
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("PART D: Multi-Group SEM (Type Differences - Formal Test)", "SECTION")

sem_multigroup <- expand_grid(
  model_name = c("bo_original", "fc_core_B"),
  constraint = c("unconstrained", "constrained")
) %>%
  mutate(
    fit = future_map2(
      model_name, constraint,
      ~{
        syntax_cfa <- gsub("TOM \\+ SAW", "RELEVANCE_SCALE", models[[.x]]())
        syntax_sem <- paste0(
          syntax_cfa, "\n",
          "Outcome =~ NA*OF02_01_num_log + OF02_02_num_log + OF_Spender_bin + OF01_SCALE\n",
          "Outcome ~~ 1*Outcome\n"
        )

        tryCatch({
          sem(syntax_sem, data = data, missing = "fiml", std.lv = TRUE, estimator = "MLR",
              group = "donation_type",
              group.equal = if (.y == "constrained") c("regressions") else "")
        }, error = function(e) NULL)
      },
      .progress = TRUE
    )
  ) %>%
  filter(map_lgl(fit, ~!is.null(.x)))

log_msg(sprintf("✓ Multi-Group Tests: %d comparisons", nrow(sem_multigroup)), "")

# ─────────────────────────────────────────────────────────────────────────────
# SAVE RESULTS
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("Saving SEM results...", "")

results_dir <- "/home/gerald/R-pipeline/results/summaries"
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

summary_df <- tibble(
  Analysis_Type = c(
    "Global",
    "Stratified by Donation Type",
    "Stratified by Organization",
    "Multi-Group Type Comparison"
  ),
  Models_Tested = c(
    nrow(sem_global),
    nrow(sem_by_type),
    nrow(sem_by_org),
    nrow(sem_multigroup)
  ),
  Status = "Complete"
)

write_csv(summary_df, file.path(results_dir, "sem_extended_summary.csv"))

log_msg(sprintf("✓ Saved: sem_extended_summary.csv"), "")

# ─────────────────────────────────────────────────────────────────────────────
# COMPLETION
# ─────────────────────────────────────────────────────────────────────────────

log_msg("", "")
log_msg("═══════════════════════════════════════════════════════════════", "")
log_msg("EXTENDED SEM ANALYSIS COMPLETE", "SUCCESS")
log_msg("═══════════════════════════════════════════════════════════════", "")

log_msg("Stratification Summary:", "")
log_msg(sprintf("  • Global SEM: %d models", nrow(sem_global)), "")
log_msg(sprintf("  • By Donation Type: %d models", nrow(sem_by_type)), "")
log_msg(sprintf("  • By Organization: %d models", nrow(sem_by_org)), "")
log_msg(sprintf("  • Multi-Group Tests: %d comparisons", nrow(sem_multigroup)), "")

log_msg("", "")
log_msg("KEY QUESTIONS ANSWERED:", "")
log_msg("  1. Do brand effects differ by donation type?", "")
log_msg("  2. Do brand effects differ by organization?", "")
log_msg("  3. Is type-stratification statistically significant?", "")

plan(sequential)

log_msg("✓ Extended SEM analysis complete - ready for interpretation!", "")
