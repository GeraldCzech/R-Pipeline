library(lavaan)

cat("Checking which variables MLR models actually used:\n")
cat("═════════════════════════════════════════════════════════\n\n")

# Check a few MLR models
models_to_check <- c(
  "sem_bo_network_OF02_01_num_structural_lavaan.rds",
  "sem_bo_network_OF02_02_num_structural_lavaan.rds",
  "sem_bo_original_OF02_01_num_structural_lavaan.rds",
  "sem_fc_first_order_OF02_01_num_structural_lavaan.rds"
)

for (model_file in models_to_check) {
  path <- file.path("v2_pipeline/C_STRUCTURAL_MODELS/outputs", model_file)
  
  if (!file.exists(path)) {
    cat(sprintf("✗ %s not found\n", model_file))
    next
  }
  
  fit <- readRDS(path)
  pt <- parameterTable(fit)
  
  # Get all variables used
  vars_used <- unique(c(pt$lhs[pt$lhs != ""], pt$rhs[pt$rhs != ""]))
  
  # Get measurement model
  meas <- pt[pt$op == "=~", c("lhs", "rhs", "est", "se")]
  
  cat(sprintf("\n%s:\n", gsub("sem_|_structural_lavaan.rds", "", model_file)))
  cat("  Measurement items:\n")
  for (i in 1:nrow(meas)) {
    cat(sprintf("    %s =~ %s (est=%.3f, se=%.3f)\n", 
                meas$lhs[i], meas$rhs[i], meas$est[i], meas$se[i]))
  }
}
