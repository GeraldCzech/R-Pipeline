library(tidyverse)

# Load and convert to dataframe like the estimation script does
data <- readRDS("pipeline_data_fc_bo.rds")
data <- as.data.frame(data)

cat("After as.data.frame():\n")
cat(sprintf("  BA03_01 class: %s\n", class(data$BA03_01)[1]))
cat(sprintf("  BA03_01 head: %s\n", paste(head(data$BA03_01, 3), collapse=", ")))
cat(sprintf("  BA03_01 unique count: %d\n", length(unique(na.omit(data$BA03_01)))))

cat("\nAfter as.numeric():\n")
v_numeric <- as.numeric(data$BA03_01)
cat(sprintf("  class: %s\n", class(v_numeric)[1]))
cat(sprintf("  head: %s\n", paste(head(v_numeric, 3), collapse=", ")))
cat(sprintf("  unique count: %d\n", length(unique(na.omit(v_numeric)))))
cat(sprintf("  all NA: %s\n", all(is.na(v_numeric))))

# Try with data extracted from factor version
cat("\n\nIf it's a factor:\n")
data2 <- as.data.frame(data)
cat(sprintf("  after data.frame, BA03_01 is: %s\n", class(data2$BA03_01)[1]))

# Try as.numeric on factors
if (is.factor(data2$BA03_01)) {
  cat("  It's a factor, as.numeric() would give factor level codes\n")
  print(as.numeric(data2$BA03_01)[1:5])
}
