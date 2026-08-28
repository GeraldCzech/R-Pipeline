#!/bin/bash
# watch_progress.sh - Live monitoring of pipeline progress
# Usage: bash watch_progress.sh

PIPELINE_DIR="/home/gerald/R-pipeline"
LOG_FILE="$PIPELINE_DIR/logs/pipeline.log"
DAEMON_LOG="$PIPELINE_DIR/logs/daemon.log"

while true; do
  clear

  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║           R-PIPELINE LIVE MONITOR                             ║"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""

  # Service status
  echo "📊 SERVICE STATUS:"
  systemctl status r-pipeline --no-pager | head -6 | tail -5
  echo ""

  # Pipeline progress stats
  echo "📈 LATEST ACTIVITY (last 10 lines):"
  echo "───────────────────────────────────────────────────────────────"
  tail -10 "$LOG_FILE" | sed 's/^/  /'
  echo ""

  # CPU/Memory usage
  echo "💻 RESOURCE USAGE:"
  ps aux | grep -E 'Rscript|pipeline_daemon' | grep -v grep | awk '{printf "  %s (CPU: %s%%, MEM: %s%%)\n", $NF, $3, $4}'
  echo ""

  # Target cache info
  if [ -d "$PIPELINE_DIR/_targets" ]; then
    CACHE_COUNT=$(ls -1 "$PIPELINE_DIR/_targets/workspaces/" 2>/dev/null | wc -l)
    echo "🎯 CACHED TARGETS: $CACHE_COUNT"
  fi
  echo ""

  echo "───────────────────────────────────────────────────────────────"
  echo "⟳ Updating every 10 seconds (Ctrl+C to stop)"
  echo "📊 For detailed stats: Rscript $PIPELINE_DIR/monitor_progress.R"
  echo "───────────────────────────────────────────────────────────────"

  sleep 10
done
