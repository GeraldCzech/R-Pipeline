#!/bin/bash
# Monitor comprehensive pipeline execution
# Checks every hour if pipeline is still running and making progress

output_file="/tmp/claude-1000/-home-gerald-R-pipeline/44ea1536-795c-44db-9a0f-f2b573928ff5/tasks/bcbkkxgv6.output"
log_file="/tmp/pipeline_monitor.log"

check_pipeline() {
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  # Check if R process is running
  if pgrep -f "COMPREHENSIVE_CORRECTED_PIPELINE.R" > /dev/null; then
    status="✓ RUNNING"
    proc_info=$(ps aux | grep -E "COMPREHENSIVE_CORRECTED_PIPELINE" | grep -v grep | awk '{print "CPU: "$3"%, MEM: "$6" KB"}')
  else
    status="✗ STOPPED"
    proc_info="Process not found"
  fi

  # Check file size and last modification
  if [ -f "$output_file" ]; then
    file_size=$(wc -l < "$output_file")
    last_mod=$(stat -c %Y "$output_file")
    current_time=$(date +%s)
    seconds_ago=$((current_time - last_mod))

    # Get last few lines showing progress
    last_lines=$(tail -3 "$output_file" | tr '\n' '|')
  else
    file_size="N/A"
    seconds_ago="N/A"
    last_lines="File not found"
  fi

  # Get current phase from output
  if grep -q "PHASE 9:" "$output_file"; then
    phase="9 (Bayesian GLM)"
  elif grep -q "PHASE 8:" "$output_file"; then
    phase="8 (Bayesian SEM)"
  else
    phase="Unknown"
  fi

  # Log results
  echo "[$timestamp] Status: $status | Phase: $phase | PID: $proc_info | Output: $file_size lines | Last update: ${seconds_ago}s ago" >> "$log_file"
  echo "Last progress: $last_lines" >> "$log_file"
  echo "---" >> "$log_file"

  # Print to console
  echo "[$timestamp] $status | Phase $phase | $file_size lines | ${seconds_ago}s ago"

  # Alert if no progress in last 30 minutes
  if [ "$seconds_ago" -gt 1800 ] && [ "$seconds_ago" != "N/A" ]; then
    echo "⚠️  WARNING: No output update for ${seconds_ago}s (>30min)"
  fi
}

# Run check
check_pipeline
