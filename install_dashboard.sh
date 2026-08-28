#!/bin/bash
# Install the R Pipeline Web Dashboard as a systemd service

set -e

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root (use: sudo bash install_dashboard.sh)"
  exit 1
fi

SERVICE_NAME="r-pipeline-dashboard"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
SCRIPT_DIR="/home/gerald/R-pipeline"

echo "=== Installing R Pipeline Web Dashboard ==="

# Check if Flask is installed
echo "Checking Python dependencies..."
python3 -m pip install flask psutil -q

# Copy service file
echo "Installing service file to ${SERVICE_FILE}..."
cp "${SCRIPT_DIR}/r-pipeline-dashboard.service" "${SERVICE_FILE}"

# Make script executable
chmod +x "${SCRIPT_DIR}/dashboard_app.py"

# Reload systemd daemon
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable service to start on boot
echo "Enabling service to start on boot..."
systemctl enable "${SERVICE_NAME}"

# Start the service
echo "Starting the dashboard service..."
systemctl start "${SERVICE_NAME}"

# Wait a moment for startup
sleep 2

# Check status
echo ""
echo "=== Installation Complete ==="
echo ""
systemctl status "${SERVICE_NAME}" --no-pager
echo ""
echo "🌐 Dashboard URL: http://localhost:5000"
echo ""
echo "Manage the dashboard:"
echo "  sudo systemctl start ${SERVICE_NAME}"
echo "  sudo systemctl stop ${SERVICE_NAME}"
echo "  sudo systemctl restart ${SERVICE_NAME}"
echo ""
echo "View logs:"
echo "  journalctl -u ${SERVICE_NAME} -f"
echo ""
