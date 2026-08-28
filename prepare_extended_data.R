#!/usr/bin/env Rscript
library(tidyverse)

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║     PREPARING DATA FOR EXTENDED MODELS                        ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

fragebogen <- readRDS("/home/gerald/10787172/output/fragebogen.rds")

cat(sprintf("✓ Loaded: %s\n\n", paste(names(fragebogen), collapse=", ")))

# Check Romero
if ("RO" %in% names(fragebogen)) {
  ro <- fragebogen$RO
  cat(sprintf("✓ Romero: %d respondents × %d variables\n", nrow(ro), ncol(ro)))
  r_items <- colnames(ro) %>% keep(~str_starts(., "R"))
  cat(sprintf("  R-items: %d\n\n", length(r_items)))
  saveRDS(ro, "pipeline_data_romero.rds")
  cat("✓ Saved: pipeline_data_romero.rds\n\n")
}

# Engagement Ladder
fc_bo <- fragebogen$FC_BO
start01 <- fragebogen$start01

fc_bo_ladder <- fc_bo %>%
  mutate(fallnr_chr = as.character(fallnr)) %>%
  left_join(
    start01 %>% transmute(fallnr = as.character(fallnr),
                          SP04 = suppressWarnings(as.numeric(as.character(SP04)))),
    by = c("fallnr_chr" = "fallnr")
  ) %>%
  select(-fallnr_chr) %>%
  mutate(
    sp04_num = replace_na(suppressWarnings(as.numeric(as.character(SP04))), 0),
    of01_num = suppressWarnings(as.numeric(as.character(OF01))),
    engagement = case_when(
      (OF_Spender == TRUE | OF_Spender == 1) & !is.na(of01_num) & of01_num >= 3 & sp04_num > 0 ~ 3L,
      (OF_Spender == TRUE | OF_Spender == 1) & !is.na(of01_num) & of01_num >= 3 & sp04_num == 0 ~ 2L,
      (OF_Spender == TRUE | OF_Spender == 1) & !is.na(of01_num) & of01_num %in% 1:2 ~ 1L,
      (OF_Spender == FALSE | OF_Spender == 0) & sp04_num == 0 ~ 0L,
      TRUE ~ NA_integer_
    ),
    engagement_lbl = factor(engagement, levels=0:3, 
      labels=c("Non-donor", "Occasional", "Regular", "Regular+Volunteer"), ordered=TRUE)
  )

cat("Engagement Ladder:\n")
print(fc_bo_ladder %>% count(engagement_lbl))
cat("\n")

saveRDS(fc_bo_ladder, "pipeline_data_fc_bo_extended_ladder.rds")
cat("✓ Saved: pipeline_data_fc_bo_extended_ladder.rds\n\n")

# EW02 Empathy Clusters
ew02_data <- start01 %>%
  transmute(fallnr = as.character(fallnr),
            across(matches("^EW02_"), ~suppressWarnings(as.numeric(as.character(.)))))

fc_bo_ew02 <- fc_bo %>%
  mutate(fallnr_chr = as.character(fallnr)) %>%
  left_join(ew02_data, by = c("fallnr_chr" = "fallnr")) %>%
  select(-fallnr_chr)

ew02_complete <- fc_bo_ew02 %>%
  select(EW02_01:EW02_05) %>%
  filter(complete.cases(.))

if (nrow(ew02_complete) > 50) {
  km <- kmeans(ew02_complete, centers=3, nstart=10)
  fc_bo_ew02$EW02_cluster <- NA_integer_
  fc_bo_ew02$EW02_cluster[complete.cases(fc_bo_ew02 %>% select(EW02_01:EW02_05))] <- km$cluster
  
  cat("EW02 Clusters (k=3):\n")
  print(fc_bo_ew02 %>% filter(!is.na(EW02_cluster)) %>% count(EW02_cluster))
  cat("\n")
}

saveRDS(fc_bo_ew02, "pipeline_data_fc_bo_extended_ew02.rds")
cat("✓ Saved: pipeline_data_fc_bo_extended_ew02.rds\n\n")

cat("═════════════════════════════════════════════════════════════════\n")
cat("Extended data READY for Phases D/M/E (Grouping/Mediation/MGSEM)\n")
