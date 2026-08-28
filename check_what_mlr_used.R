library(lavaan)

# Load a completed bo_network MLR model
fit <- readRDS("v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_bo_network_OF02_01_num_structural_lavaan.rds")

cat("bo_network MLR model inspection:\n")
cat("═════════════════════════════════════════════════════════\n\n")

# Get parameter table
pt <- parameterTable(fit)

# Show measurement model
cat("Measurement model (=~):\n")
meas <- pt[pt$op == "=~", c("lhs", "rhs", "est", "se")]
print(meas)

cat("\n\nRegression paths (~):\n")
reg <- pt[pt$op == "~", c("lhs", "rhs", "est", "se")]
print(reg)

# Get syntax
syntax <- fit@call$model
cat("\n\nStored syntax:\n")
print(syntax)
