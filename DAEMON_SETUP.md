# Pipeline Background Service Setup

This system runs your R `targets` pipeline as a persistent background service that survives terminal crashes and system reboots.

## Architecture

- **`run_pipeline.R`** — The core R script that runs `targets::tar_make()` in a loop. It logs all output to `logs/pipeline.log` and waits when all targets are up-to-date.

- **`pipeline_daemon.py`** — A Python watchdog that:
  - Starts and monitors the R process
  - Restarts it if it crashes
  - Logs daemon activity to `logs/daemon.log`
  - Handles graceful shutdown on signals

- **`r-pipeline.service`** — Systemd service unit that:
  - Starts the Python daemon on boot
  - Restarts it if it fails
  - Integrates with system logging (`journalctl`)
  - Sets resource limits (80% CPU, 4GB RAM)

## Installation

### 1. Install required packages (one-time)

Make sure all R packages from README.md are installed:

```r
install.packages(c(
  "targets", "tarchetypes", "blavaan", "rstan", "RoBMA", "brms",
  "domir", "relaimpo", "rwa", "NCA", "glmnet", "ordinalNet",
  "lme4", "glmmTMB", "tidyverse", "future", "future.callr"
))
```

### 2. Register the systemd service

```bash
sudo bash /home/gerald/R-pipeline/install_service.sh
```

This will:
- Copy the service file to `/etc/systemd/system/`
- Make scripts executable
- Enable auto-start on boot
- Reload the systemd daemon

## Usage

### Start the service

```bash
sudo systemctl start r-pipeline
```

### Check if it's running

```bash
systemctl status r-pipeline
```

### View real-time pipeline output

```bash
tail -f /home/gerald/R-pipeline/logs/pipeline.log
```

### View daemon logs (process restarts, etc.)

```bash
tail -f /home/gerald/R-pipeline/logs/daemon.log
```

### View systemd logs

```bash
journalctl -u r-pipeline -f
```

### Stop the service

```bash
sudo systemctl stop r-pipeline
```

### Restart the service

```bash
sudo systemctl restart r-pipeline
```

## Monitoring

The service automatically logs to two places:

1. **`logs/pipeline.log`** — R pipeline execution, `tar_make()` output, target status
2. **`logs/daemon.log`** — Python daemon lifecycle, restarts, errors
3. **`journalctl`** — System-level logs via `journalctl -u r-pipeline`

To see all at once (new terminal windows):

```bash
# Terminal 1: Pipeline logs
tail -f /home/gerald/R-pipeline/logs/pipeline.log

# Terminal 2: Daemon logs
tail -f /home/gerald/R-pipeline/logs/daemon.log

# Terminal 3: Systemd logs
journalctl -u r-pipeline -f
```

## Adding New Targets

To add new work to the pipeline:

1. Edit `_targets.R` and add a new `tar_target(name, expression)` block
2. Save the file
3. The daemon will automatically detect the change and run the new targets on the next iteration

No service restart needed.

## Resource Limits

The service is configured with:
- **CPU:** 80% of available cores
- **Memory:** 4GB

To adjust, edit `r-pipeline.service`:

```ini
[Service]
CPUQuota=80%        # Change this
MemoryLimit=4G      # Change this
```

Then reload:

```bash
sudo systemctl daemon-reload
sudo systemctl restart r-pipeline
```

## Troubleshooting

### Service won't start

Check systemd logs:
```bash
journalctl -u r-pipeline -n 20
```

Check if R/Python are available:
```bash
which Rscript
which python3
```

### Process keeps restarting

Check both logs:
```bash
tail -50 /home/gerald/R-pipeline/logs/pipeline.log
tail -50 /home/gerald/R-pipeline/logs/daemon.log
```

Common issues:
- Missing R packages — install them (see Installation section)
- Incorrect data paths in `_targets.R` — update to real paths
- Insufficient disk space — check `df -h`

### Manual testing

To test without systemd:

```bash
cd /home/gerald/R-pipeline
python3 pipeline_daemon.py
```

Press Ctrl+C to stop gracefully.

## Auto-start on Boot

Once installed with `install_service.sh`, the service will:
- Start automatically on system boot
- Restart if it crashes
- Be manageable with standard `systemctl` commands

To disable auto-start:
```bash
sudo systemctl disable r-pipeline
```

To re-enable:
```bash
sudo systemctl enable r-pipeline
```
