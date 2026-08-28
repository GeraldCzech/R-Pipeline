# =============================================================================
# R/data_prep.R -- Data transformation pipeline
# Calculates derived variables needed for SEM
# =============================================================================

prepare_data_for_sem <- function(raw_data) {
  library(dplyr)
  library(stringr)

  data <- raw_data %>%
    # --- Extract awareness (TOM/SAW) ---
    mutate(
      # Top-of-mind awareness (first mention exists)
      TOM = as.numeric(!is.na(BA01_01)),

      # Spontaneous awareness (any of 3 mentions)
      SAW = as.numeric(!is.na(BA01_01) | !is.na(BA01_02) | !is.na(BA01_03)),

      # --- Extract donation data ---
      # Donor status (any OF01 = TRUE)
      OF_Spender_bin = as.numeric(OF01_01 | OF01_02 | OF01_03 | OF01_04),

      # Parse OF02_01 (last donation)
      OF02_01_clean = str_replace_all(OF02_01, ",", "."),
      OF02_01_clean = str_remove_all(OF02_01_clean, "€|EUR|Euro|euro|\\s"),
      OF02_01_num = as.numeric(OF02_01_clean),
      OF02_01_num_log = log1p(OF02_01_num),

      # Parse OF02_02 (2024 donation)
      OF02_02_clean = str_replace_all(OF02_02, ",", "."),
      OF02_02_clean = str_remove_all(OF02_02_clean, "€|EUR|Euro|euro|\\s"),
      OF02_02_num = as.numeric(OF02_02_clean),
      OF02_02_num_log = log1p(OF02_02_num),

      .keep = "all"
    ) %>%
    # --- Calculate engagement ladder ---
    mutate(
      engagement_ladder = OF_Spender_bin +
        as.numeric(SAW) +
        as.numeric(!is.na(OF02_01_num) & OF02_01_num > 0) +
        as.numeric(!is.na(OF02_02_num) & OF02_02_num > 0)
    ) %>%
    # --- Standardize SES indicator ---
    mutate(
      SES_z = scale(as.numeric(SD01), center = TRUE, scale = TRUE)[,1]
    )

  return(data)
}
