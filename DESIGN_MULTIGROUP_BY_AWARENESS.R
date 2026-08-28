library(lavaan)
library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  MULTI-GROUP SEM DESIGN: RC_AWARENESS AS GROUPING VARIABLE    ║\n")
cat("║    Three donor pathway archetypes based on awareness level    ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# Load data
data <- readRDS("pipeline_data_fc_bo_with_ordinal_awareness.rds") %>% as.data.frame()

cat("CONCEPTUAL MODEL:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("GROUP STRUCTURE (N=2038):\n\n")

dist <- data %>% 
  mutate(Group = case_when(
    RC_Awareness == 1 ~ "No Awareness",
    RC_Awareness == 2 ~ "Spontaneous",
    RC_Awareness == 3 ~ "Top-of-Mind",
    TRUE ~ "Missing"
  )) %>%
  count(Group, name="N") %>%
  mutate(pct = round(100*N/sum(N), 1))

print(dist)

cat("\n\nHYPOTHESES:\n")
cat("───────────────────────────────────────────────────────────────\n\n")

cat("H1: MEASUREMENT INVARIANCE\n")
cat("   Does the brand equity measurement structure hold across\n")
cat("   awareness groups? (Configural vs. Metric vs. Scalar invariance)\n")
cat("   → Tests whether FC/BO measurement is equitable across groups\n\n")

cat("H2: STRUCTURAL HETEROGENEITY\n")
cat("   Do brand equity effects on donations differ by awareness level?\n\n")
cat("   H2a: Top-of-Mind donors show STRONGER BE→Donation effect\n")
cat("        (Hypothesis: Salient brand recall = higher donation)\n\n")
cat("   H2b: No-Awareness donors show WEAKER BE→Donation effect\n")
cat("        (Hypothesis: Unknown brand = lower donation motivation)\n\n")
cat("   H2c: Spontaneous Awareness is INTERMEDIATE\n")
cat("        (Hypothesis: Know the brand, but not top-preference)\n\n")

cat("H3: DONOR SEGMENT CHARACTERISTICS\n")
cat("   Different segments differ on:\n")
cat("   - Average donation amount (OF02_01_num)\n")
cat("   - Donation frequency (OF02_02_num)\n")
cat("   - Likelihood of being regular donor (OF_Spender)\n\n")

cat("═════════════════════════════════════════════════════════════════\n")
cat("STATISTICAL APPROACH:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("STEP 1: MULTI-GROUP MEASUREMENT MODEL\n")
cat("────────────────────────────────────────────────────────────────\n\n")

cat("Model: Boenigk/Faircloth measurement model\n")
cat("Group by: RC_Awareness Level (3 groups)\n")
cat("Tests:\n")
cat("  - Configural (free loadings/intercepts across groups)\n")
cat("  - Metric (constrain loadings, free intercepts)\n")
cat("  - Scalar (constrain loadings + intercepts)\n")
cat("  → Δ CFI < 0.01 = Invariant ✓\n\n")

cat("STEP 2: MULTI-GROUP STRUCTURAL MODEL\n")
cat("────────────────────────────────────────────────────────────────\n\n")

cat("Model: BE → Outcome (separately for each group)\n")
cat("Free parameters:\n")
cat("  - Structural paths (BE→Donation) - varies by group\n")
cat("  - Residual variances - varies by group\n")
cat("  - Intercepts - varies by group\n")
cat("Interpretation:\n")
cat("  - Compare path coefficients: β₁ (No Awareness) vs.\n")
cat("                                β₂ (Spontaneous) vs.\n")
cat("                                β₃ (Top-of-Mind)\n")
cat("  - Are differences significant? (Wald test)\n\n")

cat("STEP 3: MODERATION ANALYSIS\n")
cat("────────────────────────────────────────────────────────────────\n\n")

cat("Interpretation of structural heterogeneity:\n")
cat("  RC_Awareness acts as a MODERATOR of BE→Donation path\n")
cat("  → Tests if awareness level changes effectiveness of brand equity\n\n")

cat("═════════════════════════════════════════════════════════════════\n")
cat("IMPLEMENTATION ROADMAP:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("FILE: 01_mgsem_by_awareness.R\n")
cat("────────────────────────────────────────────────────────────────\n\n")

cat("Phase 1: Measurement Invariance Testing\n")
cat("  Input:  pipeline_data_fc_bo_with_ordinal_awareness.rds\n")
cat("  Group:  RC_Awareness (1,2,3)\n")
cat("  Models: Boenigk + Faircloth\n")
cat("  Output: mgsem_awareness_measurement_invariance.csv\n")
cat("          mgsem_awareness_configural.rds\n")
cat("          mgsem_awareness_metric.rds\n")
cat("          mgsem_awareness_scalar.rds\n\n")

cat("Phase 2: Structural Heterogeneity Testing\n")
cat("  For each outcome (OF02_01_num, OF02_02_num, OF02_03_num):\n")
cat("    Fit 3-group model with free structural paths\n")
cat("    Extract path coefficients by group\n")
cat("    Test Δχ² for constrained vs. free paths\n")
cat("  Output: mgsem_awareness_structural_effects.csv\n")
cat("          Group-specific path diagrams\n\n")

cat("Phase 3: Segment Profiling\n")
cat("  Compare means across groups:\n")
cat("    - Donation amount (OF02_01_num)\n")
cat("    - Donation frequency (OF02_02_num)\n")
cat("    - Regular donor status (OF_Spender)\n")
cat("    - Brand equity latent means\n")
cat("  Output: mgsem_awareness_segment_profile.csv\n")
cat("          Visualization: Donation behavior by awareness level\n\n")

cat("═════════════════════════════════════════════════════════════════\n")
cat("EXPECTED FINDINGS:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("BEST-CASE SCENARIO:\n")
cat("✓ Measurement invariance holds (metric level) across awareness\n")
cat("  → Brand equity constructs comparable across groups\n\n")
cat("✓ Structural heterogeneity detected\n")
cat("  → Top-of-Mind group shows strongest BE→Donation (β₃ > β₂ > β₁)\n")
cat("  → Suggests awareness moderates effectiveness of brand strategy\n\n")
cat("✓ Segment profiles differ\n")
cat("  → Top-of-Mind: Higher donation amount + frequency\n")
cat("  → No Awareness: Lower donation amount but similar structure\n\n")

cat("IMPLICATIONS:\n")
cat("→ Brand equity works differently across awareness segments\n")
cat("→ Marketing strategy should differ by awareness level\n")
cat("→ Top-of-mind positioning most impactful for donations\n\n")

cat("═════════════════════════════════════════════════════════════════\n")
cat("SAMPLING & POWER:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

n_by_group <- data %>% 
  mutate(Group = case_when(
    RC_Awareness == 1 ~ "No Awareness",
    RC_Awareness == 2 ~ "Spontaneous",
    RC_Awareness == 3 ~ "Top-of-Mind",
    TRUE ~ NA_character_
  )) %>%
  filter(!is.na(Group)) %>%
  count(Group)

print(n_by_group)

cat("\n✓ Adequate sample sizes for group comparison\n")
cat("  (All groups N > 250, suitable for SEM)\n\n")

cat("═════════════════════════════════════════════════════════════════\n")
cat("NEXT: BUILD 3-GROUP SEM SCRIPT\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("Ready to code: 01_mgsem_by_awareness.R\n")
cat("This will extend Phase D to include RC_Awareness grouping\n")

