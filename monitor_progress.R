#!/usr/bin/env Rscript
# Monitor pipeline progress - shows what's been computed and how long it took
# Usage: Rscript monitor_progress.R

library(tidyverse)

targets_dir <- "_targets"
metadata_file <- file.path(targets_dir, "meta", "meta")

if (!file.exists(metadata_file)) {
  cat("Pipeline not yet started. Run: targets::tar_make()\n")
  quit(status = 1)
}

# Read targets metadata
meta <- readRDS(metadata_file)

# Extract target information
targets_info <- meta$targets %>%
  filter(!is.na(time)) %>%
  select(name, type, time, bytes) %>%
  arrange(desc(time)) %>%
  mutate(
    time_sec = as.numeric(time),
    time_formatted = format(
      as.POSIXct(time_sec, origin = "1970-01-01"),
      "%H:%M:%S"
    ),
    size_mb = bytes / (1024^2),
    is_data = grepl("_file|_data", name),
    is_result = !is_data
  )

# Summary stats
cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("  R-PIPELINE PROGRESS MONITOR\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("\n")

n_total <- nrow(meta$targets)
n_done <- nrow(targets_info)
pct_done <- round(100 * n_done / n_total, 1)

cat(sprintf("  ✓ Computed: %d / %d targets (%.1f%%)\n", n_done, n_total, pct_done))
cat(sprintf("  ⏱  Total time: %s\n", format(sum(targets_info$time_sec, na.rm = TRUE), digits = 0)))
cat(sprintf("  💾 Total size: %.1f MB\n", sum(targets_info$size_mb, na.rm = TRUE)))

cat("\n")
cat("DATA TARGETS:\n")
cat("─────────────────────────────────────────────────────────────\n")
data_targets <- targets_info %>% filter(is_data)
if (nrow(data_targets) > 0) {
  for (i in seq_len(nrow(data_targets))) {
    row <- data_targets[i,]
    cat(sprintf("  ✓ %-30s %10.2f MB\n", row$name, row$size_mb))
  }
} else {
  cat("  (none yet)\n")
}

cat("\n")
cat("COMPUTED RESULTS (top 5 longest):\n")
cat("─────────────────────────────────────────────────────────────\n")
results <- targets_info %>% filter(is_result) %>% head(5)
if (nrow(results) > 0) {
  for (i in seq_len(nrow(results))) {
    row <- results[i,]
    cat(sprintf("  ✓ %-30s %10s  %8.2f MB\n",
      substr(row$name, 1, 30), row$time_formatted, row$size_mb))
  }
} else {
  cat("  (none yet)\n")
}

cat("\n")
cat("MISSING/PENDING (if any):\n")
cat("─────────────────────────────────────────────────────────────\n")
pending <- meta$targets %>%
  filter(is.na(time)) %>%
  pull(name)

if (length(pending) > 0) {
  for (name in pending) {
    cat(sprintf("  ⏳ %s\n", name))
  }
} else {
  cat("  (all done!)\n")
}

cat("\n")
cat("═══════════════════════════════════════════════════════════════\n")
cat("Last update:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("Run again to refresh: Rscript monitor_progress.R\n")
cat("═══════════════════════════════════════════════════════════════\n\n")
