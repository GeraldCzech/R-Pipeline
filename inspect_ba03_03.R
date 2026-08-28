library(tidyverse)

data <- readRDS("pipeline_data_fc_bo.rds")
data <- as.data.frame(data)

v <- data$BA03_03

cat("BA03_03 structure:\n")
cat(sprintf("  Class: %s\n", paste(class(v), collapse=", ")))
cat(sprintf("  Length: %d\n", length(v)))
cat(sprintf("  First 10 values:\n"))
print(v[1:10])

cat("\nAttributes:\n")
str(attributes(v))

cat("\n\nDirect coercion attempts:\n")

# Try direct as.numeric
cat("1. as.numeric():\n")
v1 <- as.numeric(v)
cat(sprintf("   Result: %d values, %d NA\n\n", sum(!is.na(v1)), sum(is.na(v1))))

# Try as.character first
cat("2. as.character() then as.numeric():\n")
v2 <- as.numeric(as.character(v))
cat(sprintf("   Result: %d values, %d NA\n", sum(!is.na(v2)), sum(is.na(v2))))
if (sum(!is.na(v2)) > 0) {
  print(head(v2, 10))
}

# Check if it's a special class with methods
cat("\n3. Methods for class 'avector':\n")
print(methods(class="avector"))
