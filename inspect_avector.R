library(tidyverse)

data_raw <- readRDS("pipeline_data_fc_bo.rds")

# Check avector structure
v <- data_raw$BA03_03
cat("avector structure:\n")
cat(sprintf("  Class: %s\n", paste(class(v), collapse=", ")))
cat(sprintf("  Length: %d\n", length(v)))
cat(sprintf("  First 5 values:\n"))
print(head(v, 5))

# Try different conversion methods
cat("\n\nConversion methods:\n")

# Method 1: Direct coercion
cat("\nMethod 1: as.numeric()\n")
v1 <- as.numeric(v)
cat(sprintf("  Result: %d values, %d NA\n", sum(!is.na(v1)), sum(is.na(v1))))

# Method 2: Attributes
cat("\nMethod 2: Inspect attributes\n")
print(attributes(v))

# Method 3: Check internal structure
cat("\nMethod 3: str()\n")
str(v)
