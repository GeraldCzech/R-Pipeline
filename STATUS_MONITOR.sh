#!/bin/bash
# Continuous Status Monitor - 30 min intervals
# Tracks SEM Analysis progress and estimates completion

PIPELINE_DIR="/home/gerald/R-pipeline"
CACHE_DIR="${PIPELINE_DIR}/cache"
START_TIME=$(date +%s)

while true; do
  CURRENT_TIME=$(date '+%Y-%m-%d %H:%M:%S')
  ELAPSED_MIN=$(( ($(date +%s) - START_TIME) / 60 ))

  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo "STATUS UPDATE: $CURRENT_TIME"
  echo "═══════════════════════════════════════════════════════════════"
  echo ""

  # Check if SEM is still running
  if ps aux | grep -v grep | grep "03_SEM_ANALYSIS" > /dev/null; then
    SEM_PID=$(pgrep -f "03_SEM_ANALYSIS")
    SEM_CPU=$(ps aux | grep $SEM_PID | grep -v grep | awk '{print $3}' || echo "0")
    echo "✓ SEM Analysis RUNNING (PID: $SEM_PID | CPU: ${SEM_CPU}%)"
  else
    echo "⏸️  SEM Analysis NOT running"
  fi

  echo "  Elapsed: ${ELAPSED_MIN} minutes"
  echo ""

  # Check cache status
  TOTAL_FITS=$(ls ${CACHE_DIR}/*.rds 2>/dev/null | wc -l)
  SEM_FITS=$(ls ${CACHE_DIR}/sem_*.rds 2>/dev/null | wc -l)
  CACHE_SIZE=$(du -sh ${CACHE_DIR} 2>/dev/null | awk '{print $1}')

  echo "Cache Status:"
  echo "  Total fits: $TOTAL_FITS"
  echo "  SEM fits: $SEM_FITS / 100"
  echo "  Cache size: $CACHE_SIZE"
  echo ""

  # Estimate completion
  if [ $SEM_FITS -gt 0 ] && [ $ELAPSED_MIN -gt 5 ]; then
    FITS_PER_MIN=$(echo "scale=2; $SEM_FITS / $ELAPSED_MIN" | bc)
    REMAINING_FITS=$(( 100 - SEM_FITS ))
    REMAINING_MIN=$(echo "scale=0; $REMAINING_FITS / $FITS_PER_MIN" | bc)
    COMPLETION_TIME=$(date -d "+${REMAINING_MIN} minutes" '+%H:%M')

    echo "Progress:"
    echo "  Rate: $FITS_PER_MIN fits/min"
    echo "  Remaining: $REMAINING_FITS fits (~${REMAINING_MIN} min)"
    echo "  ETA Completion: $COMPLETION_TIME"
  else
    echo "Progress:"
    echo "  (calculating...)"
  fi

  echo ""

  # Show latest log entries
  echo "Recent Log:"
  tail -5 ${PIPELINE_DIR}/logs/sem_analysis.log 2>/dev/null | sed 's/^/  /'

  echo ""
  echo "═══════════════════════════════════════════════════════════════"
  echo ""

  # Wait 30 minutes
  sleep 1800
done
