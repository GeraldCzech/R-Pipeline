#!/bin/bash
# Install the R pipeline as a systemd service
# Run with: sudo bash install_service.sh

set -e

echo "=== Installing R Pipeline Systemd Service ==="

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (use: sudo bash install_service.sh)"
  exit 1
fi

SERVICE_NAME="r-pipeline"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
SCRIPT_DIR="/home/gerald/R-pipeline"

# Copy service file
echo "Installing service file to ${SERVICE_FILE}..."
cp "${SCRIPT_DIR}/r-pipeline.service" "${SERVICE_FILE}"

# Make scripts executable
chmod +x "${SCRIPT_DIR}/run_pipeline.R"
chmod +x "${SCRIPT_DIR}/pipeline_daemon.py"

# Reload systemd daemon
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable service to start on boot
echo "Enabling service to start on boot..."
systemctl enable "${SERVICE_NAME}"

# Show instructions
echo ""
echo "=== Installation Complete ==="
echo ""
echo "Start the service:"
echo "  sudo systemctl start ${SERVICE_NAME}"
echo ""
echo "Check status:"
echo "  systemctl status ${SERVICE_NAME}"
echo ""
echo "View logs:"
echo "  journalctl -u ${SERVICE_NAME} -f"
echo ""
echo "View pipeline logs:"
echo "  tail -f ${SCRIPT_DIR}/logs/pipeline.log"
echo ""
echo "Stop the service:"
echo "  sudo systemctl stop ${SERVICE_NAME}"
echo ""
echo "View daemon logs:"
echo "  tail -f ${SCRIPT_DIR}/logs/daemon.log"
