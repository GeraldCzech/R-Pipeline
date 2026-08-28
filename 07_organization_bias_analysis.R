library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  BIAS ANALYSIS: Organization Effects on Brand Equity          ║\n")
cat("║  Only donors sampled → organization confounding → need MLM    ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

data <- readRDS("pipeline_data_fc_bo.rds") %>% as.data.frame()

cat("STEP 1: ORGANIZATION STRUCTURE IN DATA\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

# Check which organization variable exists
org_vars <- names(data)[grep("org|Organization|verein|Verein|NGO|ngo|Träger|träger", 
                             names(data), ignore.case=TRUE)]

cat(sprintf("Potential organization variables: %s\n\n", 
            if(length(org_vars)>0) paste(org_vars, collapse=", ") else "NONE FOUND"))

# Check metadata or original data structure
cat("Checking data structure:\n")
cat(sprintf("  N respondents: %d\n", nrow(data)))
cat(sprintf("  Columns: %d\n\n", ncol(data)))

# List all column names to identify organization variable
cat("Column names (first 50):\n")
print(names(data)[1:min(50, length(names(data)))])

# Try to find donation-related columns that might indicate organization
donation_cols <- names(data)[grep("OF|of|spende|Spende|donor|Donor", 
                                  names(data), ignore.case=TRUE)]

cat("\n\nDonation-related columns:\n")
print(donation_cols)

# CRITICAL: Load original source data to find organization variable
cat("\n\nSTEP 2: LOADING ORIGINAL SOURCE DATA\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

source_data <- readRDS("/home/gerald/10787172/output/fragebogen.rds")

cat("Source data structure:\n")
cat(sprintf("  List elements: %s\n", paste(names(source_data), collapse=", ")))

if("FC_BO" %in% names(source_data)) {
  fc_bo_source <- source_data$FC_BO %>% as.data.frame()
  
  org_cols <- names(fc_bo_source)[grep("org|verein|träger|ngo|NGO", 
                                       names(fc_bo_source), ignore.case=TRUE)]
  
  cat(sprintf("\nFC_BO source data:\n")
  cat(sprintf("  N = %d\n", nrow(fc_bo_source)))
  cat(sprintf("  Organization variable(s): %s\n\n", 
              if(length(org_cols)>0) paste(org_cols, collapse=", ") else "UNKNOWN"))
  
  # Try common identifiers
  if("Träger" %in% names(fc_bo_source)) {
    org_dist <- fc_bo_source %>% 
      group_by(Träger) %>%
      summarise(N = n(), .groups="drop") %>%
      arrange(desc(N))
    
    cat("Organization Distribution (Träger):\n")
    print(org_dist)
    
    cat(sprintf("\nRed Cross (DRK?) representation:\n")
    drk_n <- sum(grepl("Rotes Kreuz|DRK|Red Cross", org_dist$Träger, ignore.case=TRUE))
    cat(sprintf("  Overrepresented: %s\n", if(drk_n > 0) "YES" else "CHECK NAMES"))
  }
}

cat("\n\nSTEP 3: BIAS IMPLICATIONS\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("SELECTION BIAS (Only donors sampled):\n")
cat("  ✗ No non-donor control group\n")
cat("  ✗ Brand equity effects estimated only among willing givers\n")
cat("  ✗ Cannot separate brand quality from selection into giving\n\n")

cat("ORGANIZATION CONFOUNDING:\n")
cat("  ✗ Different organizations have different:\n")
cat("    • Mission alignment with donors\n")
cat("    • Brand recognition (RK might be more known)\n")
cat("    • Donor base composition\n")
cat("    • Typical donation size\n")
cat("  ✗ Organization effects could dominate brand equity effects\n\n")

cat("OVERREPRESENTATION (Red Cross):\n")
cat("  ✗ RK donors might have:\n")
cat("    • Different trust baseline (more established)\n")
cat("    • Different sensitivity to brand factors\n")
cat("    • Inflated sample influence\n\n")

cat("═════════════════════════════════════════════════════════════════\n")
cat("RECOMMENDATION: MULTI-LEVEL MODELING\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("Solution 1: RANDOM INTERCEPTS MODEL\n")
cat("  Structure: Respondents (L1) within Organizations (L2)\n")
cat("  Formula: OF ~ Brand_Equity + (1 | Organization)\n")
cat("  Effect: Controls for org-level differences\n")
cat("  Interpretation: Brand equity effect WITHIN organizations\n\n")

cat("Solution 2: RANDOM SLOPES MODEL\n")
cat("  Formula: OF ~ Brand_Equity + (1 + Brand_Equity | Organization)\n")
cat("  Effect: Tests if BE→Donation varies BY organization\n")
cat("  Interpretation: Does RK respond differently to brand?\n\n")

cat("Solution 3: ORGANIZATION AS MODERATOR\n")
cat("  Formula: OF ~ Brand_Equity * Organization\n")
cat("  Effect: Direct test of org-level heterogeneity\n")
cat("  Interpretation: Org-specific brand equity slopes\n\n")

cat("NEXT STEPS:\n")
cat("─────────────────────────────────────────────────────────────────\n\n")

cat("1. Identify organization variable in source data\n")
cat("2. Add organization to pipeline_data_fc_bo.rds\n")
cat("3. Run multi-level SEM:\n")
cat("   • Lavaan: multilevel syntax with 'cluster' argument\n")
cat("   • Mplus: TYPE=TWOLEVEL\n")
cat("   • lme4: lmer/glmer with (1|org) random intercept\n")
cat("4. Compare models:\n")
cat("   • Null model (org effect only)\n")
cat("   • Random intercepts (org + BE effects)\n")
cat("   • Random slopes (org-specific BE slopes)\n")
cat("5. Report:\n")
cat("   • ICC (Intraclass Correlation) - % variance due to org\n")
cat("   • Fixed effect of BE (pooled across orgs)\n")
cat("   • Random effect SD - how much BE varies by org\n\n")

