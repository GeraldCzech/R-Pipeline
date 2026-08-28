#!/bin/bash
# Persistent Block 1 Deep Exploration - Auto-restart on reboot
# Add to crontab: @reboot /home/gerald/R-pipeline/start_block1_persistent.sh

SCRIPT="/home/gerald/R-pipeline/01_BLOCK1_DEEP_EXPLORATION_PIPELINE.R"
LOG_DIR="/home/gerald/R-pipeline/logs"
LOG_FILE="$LOG_DIR/block1_deep_exploration.log"
PID_FILE="/tmp/block1_deep_exploration.pid"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Check if process already running
if [ -f "$PID_FILE" ]; then
  OLD_PID=$(cat "$PID_FILE")
  if kill -0 "$OLD_PID" 2>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Process already running (PID: $OLD_PID)"
    exit 0
  fi
fi

# Start analysis if not already running
if ! pgrep -f "01_BLOCK1_DEEP_EXPLORATION_PIPELINE.R" > /dev/null; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting Block 1 Deep Exploration Pipeline..."
  nohup /usr/bin/Rscript "$SCRIPT" >> "$LOG_FILE" 2>&1 &
  NEW_PID=$!
  echo "$NEW_PID" > "$PID_FILE"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Started with PID: $NEW_PID"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Process already running"
fi
