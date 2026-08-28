#!/usr/bin/env Rscript
# Monitor pipeline progress & cache status

suppressPackageStartupMessages({
  library(tidyverse)
})

monitor_progress <- function() {
  cat("\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat("PIPELINE MONITORING\n")
  cat("═══════════════════════════════════════════════════════════════\n")
  cat(sprintf("Time: %s\n", format(Sys.time(), "%Y-%m-%d %H:%M:%S")))

  # Check logs
  log_file <- "/home/gerald/R-pipeline/logs/block1_analysis.log"
  if (file.exists(log_file)) {
    log_lines <- readLines(log_file)
    last_5 <- tail(log_lines, 10)
    cat("\nRecent log entries:\n")
    for (line in last_5) {
      cat(sprintf("  %s\n", line))
    }
  }

  # Check cache
  cache_dir <- "/home/gerald/R-pipeline/cache"
  if (dir.exists(cache_dir)) {
    cache_files <- list.files(cache_dir)
    cat(sprintf("\nCache status: %d fits cached\n", length(cache_files)))
    if (length(cache_files) > 0) {
      cat("  Recent caches:\n")
      for (f in tail(cache_files, 5)) {
        size_kb <- file.size(file.path(cache_dir, f))/1024
        cat(sprintf("    ✓ %s (%.1f KB)\n", f, size_kb))
      }
    }
  }

  # Check results
  results_dir <- "/home/gerald/R-pipeline/results/summaries"
  if (dir.exists(results_dir)) {
    result_files <- list.files(results_dir)
    if (length(result_files) > 0) {
      cat(sprintf("\nResult files: %d\n", length(result_files)))
      for (f in result_files) {
        size_kb <- file.size(file.path(results_dir, f))/1024
        cat(sprintf("  ✓ %s (%.1f KB)\n", f, size_kb))

        # Try to read if CSV
        if (grepl(".csv$", f)) {
          tryCatch({
            df <- read_csv(file.path(results_dir, f), show_col_types = FALSE)
            cat(sprintf("      %d rows\n", nrow(df)))
          }, error = function(e) { NULL })
        }
      }
    }
  }

  # Active processes
  cat("\nActive R processes:\n")
  ps_output <- system("ps aux | grep 'Rscript\\|Rscript.R' | grep -v grep", intern = TRUE)
  if (length(ps_output) > 0) {
    for (line in ps_output) {
      # Extract just the important part
      parts <- strsplit(line, "\\s+")[[1]]
      pid <- parts[2]
      cmd <- paste(tail(parts, -10), collapse = " ")
      cat(sprintf("  [PID %s] %s\n", pid, substr(cmd, 1, 70)))
    }
  } else {
    cat("  None\n")
  }

  cat("\n")
}

# Run monitor
monitor_progress()

# Or run repeatedly every 60 seconds
if (Sys.getenv("MONITOR_LOOP") == "1") {
  cat("Monitoring loop active. Press Ctrl+C to stop.\n")
  while (TRUE) {
    Sys.sleep(60)
    monitor_progress()
  }
}
