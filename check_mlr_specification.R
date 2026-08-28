library(lavaan)

# Load a completed MLR model
fit <- readRDS("v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_bo_network_OF02_01_num_structural_lavaan.rds")

cat("MLR Model Specification (bo_network_OF02_01_num):\n")
cat("═════════════════════════════════════════════════════════\n\n")

# Get the original syntax
syntax <- fit@call$model
cat("Model Syntax:\n")
cat(as.character(syntax))
cat("\n\n")

# Check what variables it's actually using
pt <- parameterTable(fit)
cat("Variables in model:\n")
cat(sprintf("  Latent: %s\n", paste(unique(pt$lhs[pt$op == "=~"]), collapse=", ")))
cat(sprintf("  Measurement items: %s\n", paste(unique(pt$rhs[pt$op == "=~"]), collapse=", ")))
cat(sprintf("  Outcome: %s\n", paste(unique(pt$rhs[pt$op == "~"]), collapse=", ")))

cat("\n\nParameter estimates (loadings):\n")
loadings <- pt %>% filter(op == "=~")
print(loadings[, c("lhs", "rhs", "est", "se")])
