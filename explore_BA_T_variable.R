library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  EXPLORE BA_T: Brand Awareness Variable (z-standardized)       ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

data <- readRDS("pipeline_data_fc_bo.rds") %>% as.data.frame()

cat("Data summary:\n")
cat(sprintf("  N = %d\n", nrow(data)))
cat(sprintf("  Columns: %d\n\n", ncol(data)))

# Check if BA_T exists
if ("BA_T" %in% names(data)) {
  cat("✓ BA_T found in data\n\n")
  
  cat("BA_T Distribution:\n")
  cat("─────────────────────────────────────────────────────────────\n\n")
  
  ba_summary <- data %>% summarise(
    N = n(),
    Missing = sum(is.na(BA_T)),
    Mean = mean(BA_T, na.rm=TRUE),
    SD = sd(BA_T, na.rm=TRUE),
    Min = min(BA_T, na.rm=TRUE),
    Max = max(BA_T, na.rm=TRUE),
    Q1 = quantile(BA_T, 0.25, na.rm=TRUE),
    Median = median(BA_T, na.rm=TRUE),
    Q3 = quantile(BA_T, 0.75, na.rm=TRUE)
  )
  
  print(ba_summary)
  
  cat("\nDistribution shape:\n")
  print(data %>% select(BA_T) %>% summary())
  
  # Check correlation with TOM/SAW
  cat("\n\nCorrelation with TOM/SAW:\n")
  cat("─────────────────────────────────────────────────────────────\n\n")
  
  cors <- data %>% 
    select(BA_T, TOM, SAW) %>%
    cor(use="complete.obs")
  
  print(round(cors, 4))
  
  # Z-standardize BA_T
  data_with_z <- data %>%
    mutate(BA_T_z = as.numeric(scale(BA_T)))
  
  cat("\n\nBA_T Z-standardized:\n")
  cat("─────────────────────────────────────────────────────────────\n\n")
  
  print(data_with_z %>% select(BA_T, BA_T_z) %>% head(10))
  
  cat(sprintf("\n  Mean (should be ~0): %.4f\n", mean(data_with_z$BA_T_z, na.rm=TRUE)))
  cat(sprintf("  SD (should be ~1): %.4f\n\n", sd(data_with_z$BA_T_z, na.rm=TRUE)))
  
  # Save enhanced data
  saveRDS(data_with_z, "pipeline_data_fc_bo_with_BA_T_z.rds")
  
  cat("✓ Saved: pipeline_data_fc_bo_with_BA_T_z.rds\n")
  
} else {
  cat("✗ BA_T NOT found in data\n")
  cat("  Available columns containing 'BA':\n")
  ba_cols <- names(data)[grepl("BA", names(data), ignore.case=TRUE)]
  if (length(ba_cols) > 0) {
    print(ba_cols)
  } else {
    cat("  None found\n")
  }
  
  cat("\n  Available columns (first 30):\n")
  print(names(data)[1:min(30, length(names(data)))])
}

