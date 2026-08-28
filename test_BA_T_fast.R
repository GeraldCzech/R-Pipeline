library(lavaan)
library(tidyverse)
library(future)
library(furrr)

data <- readRDS("pipeline_data_fc_bo_with_BA_T_z.rds") %>% as.data.frame() %>%
  mutate(OF_Spender_factor = factor(OF_Spender, levels=0:1, ordered=FALSE))

cat("Testing BA_T vs TOM+SAW (fast parallel mode)\n\n")

outcomes_mlr <- c("OF02_01_num", "OF02_02_num", "OF02_03_num")
outcome_wls <- "OF_Spender_factor"

# Faircloth models
results_fc <- list()

for (outcome in outcomes_mlr) {
  fc_original <- sprintf("
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ TOM + SAW
FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
%s ~ FC_BE
", outcome)
  
  fc_ba_t <- sprintf("
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ BA_T_z
FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
%s ~ FC_BE
", outcome)
  
  fit1 <- sem(fc_original, data=data, estimator="MLR", missing="fiml", 
              std.lv=TRUE, verbose=FALSE)
  fit2 <- sem(fc_ba_t, data=data, estimator="MLR", missing="fiml",
              std.lv=TRUE, verbose=FALSE)
  
  cfi1 <- fitMeasures(fit1, "cfi")
  cfi2 <- fitMeasures(fit2, "cfi")
  
  results_fc[[outcome]] <- tibble(
    Architecture = "Faircloth",
    Outcome = outcome,
    TOM_SAW_CFI = round(cfi1, 4),
    BA_T_CFI = round(cfi2, 4),
    Delta = round(cfi2 - cfi1, 4),
    Winner = if_else(cfi1 > cfi2, "TOM+SAW", "BA_T_z")
  )
}

# Boenigk models
results_bo <- list()

for (outcome in outcomes_mlr) {
  bo_original <- sprintf("
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ TOM + SAW
BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC
%s ~ BO_BE
", outcome)
  
  bo_ba_t <- sprintf("
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ BA_T_z
BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC
%s ~ BO_BE
", outcome)
  
  fit1 <- sem(bo_original, data=data, estimator="MLR", missing="fiml",
              std.lv=TRUE, verbose=FALSE)
  fit2 <- sem(bo_ba_t, data=data, estimator="MLR", missing="fiml",
              std.lv=TRUE, verbose=FALSE)
  
  cfi1 <- fitMeasures(fit1, "cfi")
  cfi2 <- fitMeasures(fit2, "cfi")
  
  results_bo[[outcome]] <- tibble(
    Architecture = "Boenigk",
    Outcome = outcome,
    TOM_SAW_CFI = round(cfi1, 4),
    BA_T_CFI = round(cfi2, 4),
    Delta = round(cfi2 - cfi1, 4),
    Winner = if_else(cfi1 > cfi2, "TOM+SAW", "BA_T_z")
  )
}

# WLSMV binary outcome
fc_wls_orig <- "
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ TOM + SAW
FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
OF_Spender_factor ~ FC_BE
"

fc_wls_ba_t <- "
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ BA_T_z
FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
OF_Spender_factor ~ FC_BE
"

fit_fc_wls1 <- sem(fc_wls_orig, data=data, estimator="WLSMV", std.lv=TRUE, verbose=FALSE)
fit_fc_wls2 <- sem(fc_wls_ba_t, data=data, estimator="WLSMV", std.lv=TRUE, verbose=FALSE)

results_fc[[5]] <- tibble(
  Architecture = "Faircloth",
  Outcome = "OF_Spender",
  TOM_SAW_CFI = round(fitMeasures(fit_fc_wls1, "cfi"), 4),
  BA_T_CFI = round(fitMeasures(fit_fc_wls2, "cfi"), 4),
  Delta = round(fitMeasures(fit_fc_wls2, "cfi") - fitMeasures(fit_fc_wls1, "cfi"), 4),
  Winner = if_else(fitMeasures(fit_fc_wls1, "cfi") > fitMeasures(fit_fc_wls2, "cfi"), "TOM+SAW", "BA_T_z")
)

bo_wls_orig <- "
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ TOM + SAW
BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC
OF_Spender_factor ~ BO_BE
"

bo_wls_ba_t <- "
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ BA_T_z
BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC
OF_Spender_factor ~ BO_BE
"

fit_bo_wls1 <- sem(bo_wls_orig, data=data, estimator="WLSMV", std.lv=TRUE, verbose=FALSE)
fit_bo_wls2 <- sem(bo_wls_ba_t, data=data, estimator="WLSMV", std.lv=TRUE, verbose=FALSE)

results_bo[[5]] <- tibble(
  Architecture = "Boenigk",
  Outcome = "OF_Spender",
  TOM_SAW_CFI = round(fitMeasures(fit_bo_wls1, "cfi"), 4),
  BA_T_CFI = round(fitMeasures(fit_bo_wls2, "cfi"), 4),
  Delta = round(fitMeasures(fit_bo_wls2, "cfi") - fitMeasures(fit_bo_wls1, "cfi"), 4),
  Winner = if_else(fitMeasures(fit_bo_wls1, "cfi") > fitMeasures(fit_bo_wls2, "cfi"), "TOM+SAW", "BA_T_z")
)

# Summary
all_results <- bind_rows(results_fc, results_bo)
write_csv(all_results, "BA_T_comprehensive_results.csv")

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║            BA_T vs TOM+SAW: COMPREHENSIVE RESULTS              ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

print(all_results)

cat("\n\nVERDICT:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

tom_saw_count <- sum(all_results$Winner == "TOM+SAW")
ba_t_count <- sum(all_results$Winner == "BA_T_z")

cat(sprintf("TOM+SAW wins:  %d/10 models (%.0f%%)\n", tom_saw_count, 100*tom_saw_count/10))
cat(sprintf("BA_T_z wins:   %d/10 models (%.0f%%)\n\n", ba_t_count, 100*ba_t_count/10))

if (tom_saw_count >= 8) {
  cat("✓ STRONG: Keep TOM+SAW as recognition measure\n")
  cat("  → BA_T_z does not improve model fit consistently\n")
  cat("  → TOM/SAW binary indicators are optimal\n")
} else if (ba_t_count >= 8) {
  cat("✓ STRONG: Replace with BA_T_z\n")
  cat("  → Continuous brand awareness improves all models\n")
}

