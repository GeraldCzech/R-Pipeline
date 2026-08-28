library(tidyverse)

data_ordinal <- readRDS("pipeline_data_fc_bo_with_ordinal_awareness.rds") %>% as.data.frame()
data_ba_t <- readRDS("pipeline_data_fc_bo_with_BA_T_z.rds") %>% as.data.frame()

data <- data_ordinal %>%
  mutate(BA_T = data_ba_t$BA_T[1:nrow(data_ordinal)],
         BA_T_z = data_ba_t$BA_T_z[1:nrow(data_ordinal)])

cat("\n╔════════════════════════════════════════════════════════════════╗\n")
cat("║  AWARENESS MEASURES: RC_Awareness vs BA_T Comparison          ║\n")
cat("╚════════════════════════════════════════════════════════════════╝\n\n")

# Part 1: Distribution by awareness group
cat("RC_AWARENESS vs BA_T DISTRIBUTION:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

summary_by_group <- data %>%
  filter(!is.na(RC_Awareness) & !is.na(BA_T_z)) %>%
  group_by(RC_Awareness) %>%
  summarise(
    N = n(),
    BA_T_mean = mean(BA_T_z, na.rm=TRUE),
    BA_T_sd = sd(BA_T_z, na.rm=TRUE),
    BA_T_range = max(BA_T_z, na.rm=TRUE) - min(BA_T_z, na.rm=TRUE),
    .groups="drop"
  ) %>%
  mutate(Group = c("No Awareness", "Spontaneous", "Top-of-Mind")[RC_Awareness]) %>%
  select(Group, N, BA_T_mean, BA_T_sd, BA_T_range)

print(summary_by_group)

cat("\n\nCORRELATION WITH OUTCOMES:\n")
cat("═════════════════════════════════════════════════════════════════\n\n")

outcomes <- c("OF02_01_num", "OF02_02_num", "OF02_03_num", "OF01", "OF_Spender")

corr_rc <- sapply(outcomes, function(o) cor(as.numeric(data$RC_Awareness), data[[o]], use="complete.obs"))
corr_ba <- sapply(outcomes, function(o) cor(data$BA_T_z, data[[o]], use="complete.obs"))
r2_rc <- round(corr_rc^2 * 100, 2)
r2_ba <- round(corr_ba^2 * 100, 2)

comp_table <- tibble(
  Outcome = outcomes,
  RC_Awareness_r = round(corr_rc, 3),
  RC_Awareness_R2pct = r2_rc,
  BA_T_z_r = round(corr_ba, 3),
  BA_T_z_R2pct = r2_ba,
  Winner = if_else(r2_rc > r2_ba, "RC_Awareness", "BA_T_z")
)

write_csv(comp_table, "awareness_comparison.csv")
print(comp_table)

cat("\nWINNERS: RC_Awareness in", sum(comp_table$Winner=="RC_Awareness"), "/5 outcomes\n")

