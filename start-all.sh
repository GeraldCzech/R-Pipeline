#!/bin/bash
# Simple, clean startup script - no sudo needed after initial setup

set -e

LOGDIR="/home/gerald/R-pipeline/logs"
mkdir -p "$LOGDIR"

echo "🚀 R-PIPELINE STARTUP"
echo "===================="
echo ""

# Kill old processes
echo "[1/3] Cleaning up..."
pkill -f "pipeline_daemon.py" 2>/dev/null || true
pkill -f "dashboard_app.py" 2>/dev/null || true
sleep 2

# Clean cache to force recomputation
echo "[2/3] Preparing fresh run..."
rm -rf /home/gerald/R-pipeline/_targets
echo "✅ Ready"

# Start services in background
echo "[3/3] Starting services..."
echo ""

# Start pipeline daemon
/usr/bin/python3 /home/gerald/R-pipeline/pipeline_daemon.py \
  > "$LOGDIR/daemon.log" 2>&1 &
DAEMON_PID=$!
echo "✅ Pipeline daemon started (PID: $DAEMON_PID)"

# Start dashboard
/home/gerald/R-pipeline/venv/bin/python3 /home/gerald/R-pipeline/dashboard_app.py \
  > "$LOGDIR/dashboard.log" 2>&1 &
DASHBOARD_PID=$!
echo "✅ Dashboard started (PID: $DASHBOARD_PID)"

sleep 3

# Verify
echo ""
echo "===================="
echo "📊 SYSTEM READY"
echo "===================="
echo ""
echo "Dashboard: http://192.168.50.164:5000"
echo "Logs:      tail -f $LOGDIR/pipeline.log"
echo ""
echo "Processes:"
echo "  Daemon:    PID $DAEMON_PID"
echo "  Dashboard: PID $DASHBOARD_PID"
echo ""
echo "To stop:"
echo "  kill $DAEMON_PID $DASHBOARD_PID"
echo ""

# Keep script running and restart on crash
while true; do
  sleep 10

  if ! ps -p $DAEMON_PID > /dev/null 2>&1; then
    echo "⚠️  Pipeline daemon crashed, restarting..."
    /usr/bin/python3 /home/gerald/R-pipeline/pipeline_daemon.py \
      >> "$LOGDIR/daemon.log" 2>&1 &
    DAEMON_PID=$!
  fi

  if ! ps -p $DASHBOARD_PID > /dev/null 2>&1; then
    echo "⚠️  Dashboard crashed, restarting..."
    /home/gerald/R-pipeline/venv/bin/python3 /home/gerald/R-pipeline/dashboard_app.py \
      >> "$LOGDIR/dashboard.log" 2>&1 &
    DASHBOARD_PID=$!
  fi
done
