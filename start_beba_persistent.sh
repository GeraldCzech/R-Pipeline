#!/bin/bash
# Persistent BEBA 2026 Pipeline - Auto-restart on reboot
# Add to crontab: @reboot /home/gerald/R-pipeline/start_beba_persistent.sh

SCRIPT="/home/gerald/R-pipeline/01_BEBA_PIPELINE_v8 (1).R"
LOG_DIR="/home/gerald/R-pipeline/logs"
LOG_FILE="$LOG_DIR/beba_pipeline.log"
PID_FILE="/tmp/beba_pipeline.pid"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Check if process already running
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat "$PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BEBA process already running (PID: $OLD_PID)"
    exit 0
  fi
fi

# Start BEBA if not already running
if ! pgrep -f "01_BEBA_PIPELINE" > /dev/null; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting BEBA 2026 Pipeline..."
  nohup /usr/bin/Rscript "$SCRIPT" >> "$LOG_FILE" 2>&1 &
  NEW_PID=$!
  echo "$NEW_PID" > "$PID_FILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Started BEBA with PID: $NEW_PID"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] BEBA process already running"
fi
