library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  CREATE ORDINAL AWARENESS SCALE (SAW/TOM → 3-Level Ordinal)  ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# Load data
data <- readRDS("pipeline_data_fc_bo.rds") %>% as.data.frame()

cat("Input data:\n")
cat(sprintf("  N = %d\n", nrow(data)))
cat(sprintf("  SAW unique: %s\n", paste(sort(unique(na.omit(data$SAW))), collapse=", ")))
cat(sprintf("  TOM unique: %s\n", paste(sort(unique(na.omit(data$TOM))), collapse=", ")))
cat(sprintf("  Both missing: %d\n\n", sum(is.na(data$SAW) & is.na(data$TOM))))

# Create ordinal awareness scale
data <- data %>%
  mutate(
    SAW_num = as.numeric(SAW),
    TOM_num = as.numeric(TOM),
    
    RC_Awareness = case_when(
      is.na(SAW_num) & is.na(TOM_num) ~ NA_integer_,
      TOM_num == 1 ~ 3L,
      SAW_num == 1 & (is.na(TOM_num) | TOM_num == 0) ~ 2L,
      SAW_num == 0 | (is.na(SAW_num) & TOM_num == 0) ~ 1L,
      TRUE ~ NA_integer_
    ),
    
    RC_Awareness_lbl = factor(RC_Awareness,
      levels = 1:3,
      labels = c("No Awareness", "Spontaneous", "Top-of-Mind"),
      ordered = TRUE)
  )

cat("NEW ORDINAL AWARENESS SCALE:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

dist <- data %>% count(RC_Awareness_lbl, name = "n") %>%
  mutate(pct = round(100*n/sum(n), 1))

print(dist)

cat("\n\nVALIDATION:\n")
cat("─────────────────────────────────────────────────────────────────\n\n")

cat(sprintf("Total with awareness score: %d/%d (%.1f%%)\n",
            sum(!is.na(data$RC_Awareness)), nrow(data),
            100*mean(!is.na(data$RC_Awareness))))

# Save enhanced data
data_enhanced <- data %>% select(-SAW_num, -TOM_num)

saveRDS(data_enhanced, "pipeline_data_fc_bo_with_ordinal_awareness.rds")

cat("\n✓ Saved: pipeline_data_fc_bo_with_ordinal_awareness.rds\n")
cat("  New variable: RC_Awareness (ordinal, 1-3)\n")
cat("  Variable: RC_Awareness_lbl (labeled factor)\n\n")

cat("POTENTIAL IMPROVEMENT:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("Using ordinal RC_Awareness could improve fit because:\n\n")
cat("1. BETTER CAPTURES AWARENESS HIERARCHY\n")
cat("   Current: Two separate items (TOM, SAW) treated as continuous\n")
cat("   Proposed: Single ordinal scale (no → spontaneous → top-of-mind)\n")
cat("   → More aligned with theory\n\n")

cat("2. ALLOWS CATEGORICAL ESTIMATOR\n")
cat("   Current: MLR (continuous estimator)\n")
cat("   Proposed: WLSMV (ordinal-appropriate)\n")
cat("   → May improve fit for categorical structure\n\n")

cat("3. REDUCES MEASUREMENT ERROR\n")
cat("   Current: Two items with measurement noise\n")
cat("   Proposed: Composite ordinal with clearer levels\n")
cat("   → Cleaner signal\n\n")

cat("IMPLEMENTATION NEXT:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

cat("Models to re-estimate:\n")
cat("  BO_RC =~ RC_Awareness (instead of TOM + SAW)\n")
cat("  FC_RC =~ RC_Awareness (instead of TOM + SAW)\n")
cat("  Estimator: WLSMV (for ordinal structure)\n")
cat("  ordered = 'RC_Awareness' in sem() call\n")
