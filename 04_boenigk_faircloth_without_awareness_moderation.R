#!/usr/bin/env Rscript
library(lavaan)
library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  BOENIGK & FAIRCLOTH: Awareness-Free + Moderation Test        ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

base_dir <- "/home/gerald/R-pipeline"
output_dir <- file.path(base_dir, "v2_pipeline/C_STRUCTURAL_MODELS/outputs")

data <- readRDS(file.path(base_dir, "pipeline_data_fc_bo_with_ordinal_awareness.rds")) %>%
  as.data.frame()

cat(sprintf("Data: N=%d\n\n", nrow(data)))

fc_no_awareness <- "
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_BE =~ FC_BR + FC_BD + FC_BF
"

bo_no_awareness <- "
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_BE =~ BO_TR + BO_CO + BO_BF
"

# Use only main outcomes (skip OF01 which has convergence issues)
outcomes_mlr <- c("OF02_01_num", "OF02_02_num", "OF02_03_num")

# ─────────────────────────────────────────────────────────────────────────────
# PART 1: Awareness-Free Baseline
# ─────────────────────────────────────────────────────────────────────────────

cat("PART 1: AWARENESS-FREE BASELINE MODELS\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

results_baseline <- list()

cat("FAIRCLOTH (without TOM/SAW):\n")
for (outcome in outcomes_mlr) {
  syntax <- sprintf("%s\n%s ~ FC_BE\n", fc_no_awareness, outcome)
  fit <- sem(syntax, data=data, estimator="MLR", missing="fiml",
             std.lv=TRUE, verbose=FALSE)
  
  cfi <- fitMeasures(fit, "cfi")
  rmsea <- fitMeasures(fit, "rmsea")
  cat(sprintf("  %s: CFI=%.4f\n", outcome, cfi))
  
  results_baseline[[paste0("FC_", outcome)]] <- list(
    Architecture = "Faircloth", Outcome = outcome, CFI = cfi, RMSEA = rmsea
  )
}

cat("\nBOENIGK (without TOM/SAW):\n")
for (outcome in outcomes_mlr) {
  syntax <- sprintf("%s\n%s ~ BO_BE\n", bo_no_awareness, outcome)
  fit <- sem(syntax, data=data, estimator="MLR", missing="fiml",
             std.lv=TRUE, verbose=FALSE)
  
  cfi <- fitMeasures(fit, "cfi")
  rmsea <- fitMeasures(fit, "rmsea")
  cat(sprintf("  %s: CFI=%.4f\n", outcome, cfi))
  
  results_baseline[[paste0("BO_", outcome)]] <- list(
    Architecture = "Boenigk", Outcome = outcome, CFI = cfi, RMSEA = rmsea
  )
}

baseline_df <- map_df(results_baseline, ~as_tibble(.))
write_csv(baseline_df, file.path(output_dir, "04_awareness_free_baseline.csv"))

# ─────────────────────────────────────────────────────────────────────────────
# PART 2: Moderation Test with RC_Awareness
# ─────────────────────────────────────────────────────────────────────────────

cat("\n\nPART 2: MODERATION - RC_Awareness as Direct Predictor\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

data_mod <- data %>%
  filter(!is.na(RC_Awareness)) %>%
  mutate(RC_Aware_c = scale(as.numeric(RC_Awareness))[,1])

cat(sprintf("Sample with RC_Awareness: N=%d\n\n", nrow(data_mod)))

results_moderation <- list()

outcome <- "OF02_01_num"  # Primary outcome

cat(sprintf("Testing moderation on: %s\n\n", outcome)

# FAIRCLOTH
cat("FAIRCLOTH:\n")

fc_mod_no <- sprintf("%s\n%s ~ FC_BE\n", fc_no_awareness, outcome)
fc_mod_yes <- sprintf("%s\n%s ~ FC_BE + RC_Aware_c\n", fc_no_awareness, outcome)

fit_fc_no <- sem(fc_mod_no, data=data_mod, estimator="MLR", missing="fiml",
                 std.lv=TRUE, verbose=FALSE)
fit_fc_yes <- sem(fc_mod_yes, data=data_mod, estimator="MLR", missing="fiml",
                  std.lv=TRUE, verbose=FALSE)

be_path_fc_no <- parameterEstimates(fit_fc_no) %>%
  filter(lhs == outcome & rhs == "FC_BE") %>% pull(est) %>% .[1]

be_path_fc_yes <- parameterEstimates(fit_fc_yes) %>%
  filter(lhs == outcome & rhs == "FC_BE") %>% pull(est) %>% .[1]

rc_path_fc <- parameterEstimates(fit_fc_yes) %>%
  filter(lhs == outcome & rhs == "RC_Aware_c") %>% pull(est) %>% .[1]

cfi_fc_no <- fitMeasures(fit_fc_no, "cfi")
cfi_fc_yes <- fitMeasures(fit_fc_yes, "cfi")

cat(sprintf("  Without RC_Aware: BE→Outcome = %.4f (CFI=%.4f)\n", be_path_fc_no, cfi_fc_no))
cat(sprintf("  With RC_Aware:    BE→Outcome = %.4f (CFI=%.4f)\n", be_path_fc_yes, cfi_fc_yes))
cat(sprintf("                    RC→Outcome = %.4f\n", rc_path_fc))
cat(sprintf("  Path change: Δ = %.4f (%.1f%%)\n\n",
            be_path_fc_yes - be_path_fc_no,
            100*(be_path_fc_yes - be_path_fc_no)/be_path_fc_no))

results_moderation[["FC"]] <- list(
  Architecture = "Faircloth",
  BE_without = be_path_fc_no,
  BE_with_RC = be_path_fc_yes,
  RC_direct = rc_path_fc,
  CFI_without = cfi_fc_no,
  CFI_with = cfi_fc_yes
)

# BOENIGK
cat("BOENIGK:\n")

bo_mod_no <- sprintf("%s\n%s ~ BO_BE\n", bo_no_awareness, outcome)
bo_mod_yes <- sprintf("%s\n%s ~ BO_BE + RC_Aware_c\n", bo_no_awareness, outcome)

fit_bo_no <- sem(bo_mod_no, data=data_mod, estimator="MLR", missing="fiml",
                 std.lv=TRUE, verbose=FALSE)
fit_bo_yes <- sem(bo_mod_yes, data=data_mod, estimator="MLR", missing="fiml",
                  std.lv=TRUE, verbose=FALSE)

be_path_bo_no <- parameterEstimates(fit_bo_no) %>%
  filter(lhs == outcome & rhs == "BO_BE") %>% pull(est) %>% .[1]

be_path_bo_yes <- parameterEstimates(fit_bo_yes) %>%
  filter(lhs == outcome & rhs == "BO_BE") %>% pull(est) %>% .[1]

rc_path_bo <- parameterEstimates(fit_bo_yes) %>%
  filter(lhs == outcome & rhs == "BO_BE") %>% pull(est) %>% .[1]

cfi_bo_no <- fitMeasures(fit_bo_no, "cfi")
cfi_bo_yes <- fitMeasures(fit_bo_yes, "cfi")

cat(sprintf("  Without RC_Aware: BE→Outcome = %.4f (CFI=%.4f)\n", be_path_bo_no, cfi_bo_no))
cat(sprintf("  With RC_Aware:    BE→Outcome = %.4f (CFI=%.4f)\n", be_path_bo_yes, cfi_bo_yes))
cat(sprintf("                    RC→Outcome = %.4f\n", rc_path_bo))
cat(sprintf("  Path change: Δ = %.4f (%.1f%%)\n\n",
            be_path_bo_yes - be_path_bo_no,
            100*(be_path_bo_yes - be_path_bo_no)/be_path_bo_no))

results_moderation[["BO"]] <- list(
  Architecture = "Boenigk",
  BE_without = be_path_bo_no,
  BE_with_RC = be_path_bo_yes,
  RC_direct = rc_path_bo,
  CFI_without = cfi_bo_no,
  CFI_with = cfi_bo_yes
)

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║                    COMPREHENSIVE SUMMARY                       ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

mod_df <- map_df(results_moderation, ~as_tibble(.))
write_csv(mod_df, file.path(output_dir, "04_moderation_results.csv"))

print(baseline_df)
cat("\n")
print(mod_df)

cat("\n\nKEY FINDINGS:\n")
cat("─────────────────────────────────────────────────────────────────\n\n")

cat("FAIRCLOTH:\n")
cat(sprintf("  Base BE effect: %.4f\n", be_path_fc_no))
cat(sprintf("  With RC_Aware:  %.4f (change: %.1f%%)\n",
            be_path_fc_yes, 100*(be_path_fc_yes-be_path_fc_no)/be_path_fc_no))
cat(sprintf("  RC_Aware direct: %.4f\n\n", rc_path_fc))

cat("BOENIGK:\n")
cat(sprintf("  Base BE effect: %.4f\n", be_path_bo_no))
cat(sprintf("  With RC_Aware:  %.4f (change: %.1f%%)\n",
            be_path_bo_yes, 100*(be_path_bo_yes-be_path_bo_no)/be_path_bo_no))
cat(sprintf("  RC_Aware direct: %.4f\n\n", rc_path_bo))

if (abs(be_path_fc_yes - be_path_fc_no) < 0.01) {
  cat("✓ CONCLUSION: RC_Awareness and Brand Equity are INDEPENDENT predictors\n")
  cat("  → Both should be included in donation prediction models\n")
  cat("  → No mediation/moderation effect\n")
} else {
  cat("✓ CONCLUSION: RC_Awareness partially MEDIATES BE effect\n")
  cat("  → Awareness level affects how strongly BE drives donations\n")
}

