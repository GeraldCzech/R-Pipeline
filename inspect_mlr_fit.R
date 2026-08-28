library(lavaan)

# Load the MLR model
fit_mlr <- readRDS("v2_pipeline/C_STRUCTURAL_MODELS/outputs/sem_bo_network_OF02_01_num_structural_lavaan.rds")

cat("MLR Model Details (bo_network_OF02_01_num):\n")
cat("═════════════════════════════════════════════════════════\n\n")

# Check convergence and sample info
cat(sprintf("Converged: %s\n", lavInspect(fit_mlr, "converged")))
cat(sprintf("N obs: %s\n", fitMeasures(fit_mlr, "nobs")))

# Get parameter table
pt <- parameterTable(fit_mlr)
cat("\nParameter table (first 10 rows):\n")
print(pt[1:10, c("lhs", "op", "rhs", "est", "se")])

# Get data
data_obj <- fit_mlr@Data
cat("\nData object info:\n")
cat(sprintf("  nobs: %d\n", nrow(data_obj$X)))
cat(sprintf("  nvars: %d\n", ncol(data_obj$X)))
cat(sprintf("  Variable types: %s\n", paste(data_obj$ov.types, collapse=", ")))

# Show actual variable values used
X <- data_obj$X
cat("\nFirst 5 rows of estimation data:\n")
print(head(X, 5))

cat("\nVariable classes:\n")
print(sapply(as.data.frame(X), class))
