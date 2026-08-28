#!/usr/bin/env Rscript
library(tidyverse)

data <- readRDS("pipeline_data_fc_bo.rds") %>% as.data.frame()

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  ORGANIZATION BIAS ASSESSMENT                                  ║\n")
cat("║  Selection: Only donors → Organization confounds effects      ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

if("org" %in% names(data)) {
  org_dist <- data %>%
    group_by(org) %>%
    summarise(
      N = n(),
      N_pct = round(100*n()/nrow(data), 1),
      Donation_Amt = round(mean(OF02_01_num, na.rm=TRUE), 2),
      Donation_Freq = round(mean(OF02_02_num, na.rm=TRUE), 1),
      Regular_Donor_pct = round(100*mean(OF_Spender, na.rm=TRUE), 1),
      .groups="drop"
    ) %>%
    arrange(desc(N))

  cat("ORGANIZATION DISTRIBUTION:\n")
  cat("═════════════════════════════════════════════════════════════════\n\n")
  print(org_dist)

  write_csv(org_dist, "organization_distribution.csv")

  cat("\n\nBIAS INDICATORS:\n")
  cat("─────────────────────────────────────────────────────────────────\n\n")

  cat(sprintf("Largest org: %s (N=%d, %.1f%%)\n", org_dist$org[1], org_dist$N[1], org_dist$N_pct[1]))
  cat(sprintf("Smallest org: %s (N=%d, %.1f%%)\n", org_dist$org[nrow(org_dist)],
              org_dist$N[nrow(org_dist)], org_dist$N_pct[nrow(org_dist)]))

  # Check donation differences
  donation_diff <- max(org_dist$Donation_Amt) - min(org_dist$Donation_Amt)
  cat(sprintf("\nDonation amount range: $%.2f (HIGH VARIABILITY)\n", donation_diff))

  # ANOVA test
  anova_result <- aov(OF02_01_num ~ org, data=data)
  f_stat <- summary(anova_result)[[1]]$`F value`[1]
  p_val <- summary(anova_result)[[1]]$`Pr(>F)`[1]

  cat(sprintf("Organization effect on donations (ANOVA):\n"))
  cat(sprintf("  F = %.2f, p = %.4f\n", f_stat, p_val))

  if(p_val < 0.001) {
    cat("  ✗ ORGANIZATION EFFECT IS HIGHLY SIGNIFICANT\n")
    cat("  → BIAS CONFIRMED: Cannot ignore organization variable\n\n")
  }

} else {
  cat("✗ 'org' variable not found in data\n")
}

cat("\n═════════════════════════════════════════════════════════════════\n")
cat("SOLUTION: MULTI-LEVEL SEM\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("WHY STANDARD SEM FAILS:\n")
cat("  • Standard SEM assumes independence of observations\n")
cat("  • Observations within org are correlated (ICC > 0)\n")
cat("  • Ignoring clustering underestimates standard errors\n")
cat("  • Makes estimates appear more significant than they are\n\n")

cat("MULTI-LEVEL SEM SOLUTION:\n")
cat("  ✓ Accounts for organization clustering\n")
cat("  ✓ Separates within-org effects from between-org effects\n")
cat("  ✓ Adjusts standard errors correctly\n")
cat("  ✓ Tests if brand equity effects vary by org\n\n")

cat("IMPLEMENTATION APPROACHES:\n\n")

cat("1. LAVAAN MULTILEVEL (simplest)\n")
cat("   fit <- sem(model, data=data, cluster='org')\n")
cat("   Effect: Corrects SEs for within-org correlation\n\n")

cat("2. RANDOM INTERCEPTS (intermediate)\n")
cat("   Two-level model: Respondent → Organization\n")
cat("   Allows organization-specific intercepts\n")
cat("   Tests if baseline donation varies by org\n\n")

cat("3. RANDOM SLOPES (advanced)\n")
cat("   Allows brand equity effect to vary by organization\n")
cat("   Answer: Does RK respond differently to brand quality?\n")
cat("   Model: OF ~ BE + (1 + BE | org)\n\n")

cat("NEXT STEP:\n")
cat("  Build multi-level Chatzipanagiotou model with lavaan 'cluster'\n")
cat("  Compare: Standard SEM vs Clustered SEM\n")
cat("  Report: ICC (how much variance due to org clustering)\n\n")

