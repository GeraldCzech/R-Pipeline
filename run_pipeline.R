#!/usr/bin/env Rscript
# run_pipeline.R -- Persistent targets pipeline executor with logging
# Runs tar_make() in a loop, logs to logs/pipeline.log

library(targets)

log_file <- "logs/pipeline.log"
dir.create("logs", showWarnings = FALSE)

log_msg <- function(msg) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  msg_formatted <- sprintf("[%s] %s", timestamp, msg)
  cat(msg_formatted, "\n")
  cat(msg_formatted, "\n", file = log_file, append = TRUE)
}

log_msg("Pipeline executor started")
log_msg(sprintf("R version: %s", R.version$version.string))
log_msg(sprintf("Working directory: %s", getwd()))

# Graceful shutdown on exit
on.exit({
  log_msg("Pipeline executor stopped")
})

# Main loop
iteration <- 0
repeat {
  iteration <- iteration + 1
  log_msg(sprintf("=== Iteration %d ===", iteration))

  tryCatch({
    targets::tar_make(reporter = "verbose")
    log_msg("tar_make() completed successfully")
  }, error = function(e) {
    log_msg(sprintf("ERROR in tar_make(): %s", conditionMessage(e)))
    log_msg(sprintf("Stack: %s", paste(capture.output(traceback()), collapse = "\n")))
  }, warning = function(w) {
    log_msg(sprintf("WARNING in tar_make(): %s", conditionMessage(w)))
  })

  # Check if all targets are up to date (nothing to do)
  status <- tryCatch({
    targets::tar_outdated()
  }, error = function(e) {
    log_msg(sprintf("ERROR checking targets status: %s", conditionMessage(e)))
    NA
  })

  if (length(status) == 0) {
    log_msg("All targets are up to date. Waiting 300s before checking again...")
    Sys.sleep(300)
  } else {
    log_msg(sprintf("Found %d outdated targets, continuing immediately", length(status)))
  }
}
