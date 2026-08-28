library(lavaan)
library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  TEST BA_T: ALL OUTCOMES (5 models per specification)          ║\n")
cat("║    Faircloth & Boenigk: OF02_01/02/03, OF01, OF_Spender      ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

data <- readRDS("pipeline_data_fc_bo_with_BA_T_z.rds") %>% as.data.frame() %>%
  mutate(OF_Spender_factor = factor(OF_Spender, levels=0:1, ordered=FALSE))

cat(sprintf("Data: N=%d\n", nrow(data)))
cat(sprintf("Complete cases: %d (%.1f%%)\n\n", 
            sum(complete.cases(data[, c("OF02_01_num", "BA_T_z", "TOM", "SAW")])),
            100*mean(complete.cases(data[, c("OF02_01_num", "BA_T_z", "TOM", "SAW")]))))

# Define outcomes
outcomes_mlr <- c("OF02_01_num", "OF02_02_num", "OF02_03_num", "OF01")
outcome_wls <- "OF_Spender_factor"

# ─────────────────────────────────────────────────────────────────────────────
# FAIRCLOTH: All outcomes
# ─────────────────────────────────────────────────────────────────────────────

cat("═══════════════════════════════════════════════════════════════════════════\n")
cat("FAIRCLOTH: Recognition Specifications Across All Outcomes\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

fc_results <- list()

for (outcome in outcomes_mlr) {
  cat(sprintf("%s:\n", outcome))
  
  # Spec 1: TOM+SAW
  fc1 <- sprintf("
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ TOM + SAW
FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
%s ~ FC_BE
", outcome)
  
  fit1 <- sem(fc1, data=data, estimator="MLR", missing="fiml", std.lv=TRUE, verbose=FALSE)
  cfi1 <- fitMeasures(fit1, "cfi")
  
  # Spec 2: BA_T_z
  fc2 <- sprintf("
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ BA_T_z
FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
%s ~ FC_BE
", outcome)
  
  fit2 <- sem(fc2, data=data, estimator="MLR", missing="fiml", std.lv=TRUE, verbose=FALSE)
  cfi2 <- fitMeasures(fit2, "cfi")
  
  cat(sprintf("  TOM+SAW: CFI=%.4f | BA_T_z: CFI=%.4f Δ=%+.4f\n\n",
              cfi1, cfi2, cfi2-cfi1))
  
  fc_results[[outcome]] <- list(Outcome=outcome, TOM_SAW=cfi1, BA_T_z=cfi2, 
                                Delta=cfi2-cfi1, Best=if_else(cfi1>cfi2, "TOM+SAW", "BA_T_z"))
}

# OF_Spender with WLSMV
cat(sprintf("%s (WLSMV):\n", outcome_wls))

fc1_wls <- "
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ TOM + SAW
FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
OF_Spender_factor ~ FC_BE
"

fit1_wls <- sem(fc1_wls, data=data, estimator="WLSMV", std.lv=TRUE, verbose=FALSE)
cfi1_wls <- fitMeasures(fit1_wls, "cfi")

fc2_wls <- "
FC_BR =~ FC01_01 + FC01_02 + FC01_03
FC_BD =~ FC01_04 + FC01_05 + FC01_06
FC_BF =~ FC03_01 + FC03_02 + FC03_03
FC_RC =~ BA_T_z
FC_BE =~ FC_BR + FC_BD + FC_BF + FC_RC
OF_Spender_factor ~ FC_BE
"

fit2_wls <- sem(fc2_wls, data=data, estimator="WLSMV", std.lv=TRUE, verbose=FALSE)
cfi2_wls <- fitMeasures(fit2_wls, "cfi")

cat(sprintf("  TOM+SAW: CFI=%.4f | BA_T_z: CFI=%.4f Δ=%+.4f\n\n",
            cfi1_wls, cfi2_wls, cfi2_wls-cfi1_wls))

fc_results[["OF_Spender"]] <- list(Outcome="OF_Spender", TOM_SAW=cfi1_wls, BA_T_z=cfi2_wls,
                                    Delta=cfi2_wls-cfi1_wls, Best=if_else(cfi1_wls>cfi2_wls, "TOM+SAW", "BA_T_z"))

# ─────────────────────────────────────────────────────────────────────────────
# BOENIGK: All outcomes
# ─────────────────────────────────────────────────────────────────────────────

cat("═══════════════════════════════════════════════════════════════════════════\n")
cat("BOENIGK: Recognition Specifications Across All Outcomes\n")
cat("═══════════════════════════════════════════════════════════════════════════\n\n")

bo_results <- list()

for (outcome in outcomes_mlr) {
  cat(sprintf("%s:\n", outcome))
  
  # Spec 1: TOM+SAW
  bo1 <- sprintf("
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ TOM + SAW
BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC
%s ~ BO_BE
", outcome)
  
  fit1 <- sem(bo1, data=data, estimator="MLR", missing="fiml", std.lv=TRUE, verbose=FALSE)
  cfi1 <- fitMeasures(fit1, "cfi")
  
  # Spec 2: BA_T_z
  bo2 <- sprintf("
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ BA_T_z
BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC
%s ~ BO_BE
", outcome)
  
  fit2 <- sem(bo2, data=data, estimator="MLR", missing="fiml", std.lv=TRUE, verbose=FALSE)
  cfi2 <- fitMeasures(fit2, "cfi")
  
  cat(sprintf("  TOM+SAW: CFI=%.4f | BA_T_z: CFI=%.4f Δ=%+.4f\n\n",
              cfi1, cfi2, cfi2-cfi1))
  
  bo_results[[outcome]] <- list(Outcome=outcome, TOM_SAW=cfi1, BA_T_z=cfi2,
                                Delta=cfi2-cfi1, Best=if_else(cfi1>cfi2, "TOM+SAW", "BA_T_z"))
}

# OF_Spender with WLSMV
cat(sprintf("%s (WLSMV):\n", outcome_wls))

bo1_wls <- "
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ TOM + SAW
BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC
OF_Spender_factor ~ BO_BE
"

fit1_wls <- sem(bo1_wls, data=data, estimator="WLSMV", std.lv=TRUE, verbose=FALSE)
cfi1_wls <- fitMeasures(fit1_wls, "cfi")

bo2_wls <- "
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ BA_T_z
BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC
OF_Spender_factor ~ BO_BE
"

fit2_wls <- sem(bo2_wls, data=data, estimator="WLSMV", std.lv=TRUE, verbose=FALSE)
cfi2_wls <- fitMeasures(fit2_wls, "cfi")

cat(sprintf("  TOM+SAW: CFI=%.4f | BA_T_z: CFI=%.4f Δ=%+.4f\n\n",
            cfi1_wls, cfi2_wls, cfi2_wls-cfi1_wls))

bo_results[["OF_Spender"]] <- list(Outcome="OF_Spender", TOM_SAW=cfi1_wls, BA_T_z=cfi2_wls,
                                    Delta=cfi2_wls-cfi1_wls, Best=if_else(cfi1_wls>cfi2_wls, "TOM+SAW", "BA_T_z"))

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────

cat("╔════════════════════════════════════════════════════════════════╗\n")
cat("║                  COMPREHENSIVE COMPARISON                      ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

fc_df <- map_df(fc_results, ~as_tibble(.)) %>% mutate(Architecture="Faircloth")
bo_df <- map_df(bo_results, ~as_tibble(.)) %>% mutate(Architecture="Boenigk")

all_df <- bind_rows(fc_df, bo_df) %>% select(Architecture, everything())

write_csv(all_df, "BA_T_all_outcomes_comparison.csv")
print(all_df)

cat("\n\nSUMMARY:\n")
cat("─────────────────────────────────────────────────────────────────\n\n")

tom_saw_wins <- sum(all_df$Best == "TOM+SAW")
ba_t_wins <- sum(all_df$Best == "BA_T_z")

cat(sprintf("TOM+SAW better: %d/10 models\n", tom_saw_wins))
cat(sprintf("BA_T_z better:  %d/10 models\n\n", ba_t_wins))

if (tom_saw_wins > ba_t_wins) {
  cat("✓ CONCLUSION: TOM+SAW remains superior across outcomes\n")
  cat("  → Keep original recognition measurement\n")
  cat("  → BA_T_z does not improve Brand Equity models\n")
} else if (ba_t_wins > tom_saw_wins) {
  cat("✓ CONCLUSION: BA_T_z is superior\n")
  cat("  → Replace TOM+SAW with BA_T_z\n")
  cat("  → Continuous awareness measure preferred\n")
}

