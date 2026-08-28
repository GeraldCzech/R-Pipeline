#!/usr/bin/env python3
"""
Pipeline Daemon — monitors and restarts R pipeline process
Logs to logs/daemon.log
"""

import subprocess
import time
import os
import sys
import signal
from datetime import datetime
from pathlib import Path

class PipelineDaemon:
    def __init__(self, work_dir="/home/gerald/R-pipeline"):
        self.work_dir = Path(work_dir)
        self.log_file = self.work_dir / "logs" / "daemon.log"
        self.log_file.parent.mkdir(parents=True, exist_ok=True)
        self.process = None
        self.running = True

        # Graceful shutdown handlers
        signal.signal(signal.SIGTERM, self._handle_signal)
        signal.signal(signal.SIGINT, self._handle_signal)

    def log(self, msg):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        formatted = f"[{timestamp}] {msg}"
        print(formatted)
        with open(self.log_file, "a") as f:
            f.write(formatted + "\n")

    def _handle_signal(self, sig, frame):
        self.log(f"Received signal {sig}, shutting down gracefully...")
        self.running = False
        if self.process:
            self.process.terminate()
            try:
                self.process.wait(timeout=10)
            except subprocess.TimeoutExpired:
                self.log("Process did not terminate, killing...")
                self.process.kill()

    def run(self):
        self.log("Pipeline daemon started")
        self.log(f"Working directory: {self.work_dir}")
        self.log(f"Python version: {sys.version.split()[0]}")

        os.chdir(self.work_dir)
        restart_count = 0

        while self.running:
            restart_count += 1
            self.log(f"--- Restart #{restart_count} ---")

            try:
                # Start the R pipeline process
                self.process = subprocess.Popen(
                    ["Rscript", "run_pipeline.R"],
                    cwd=self.work_dir,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1
                )

                self.log(f"Started R process (PID: {self.process.pid})")

                # Stream output from the process
                while self.running and self.process.poll() is None:
                    try:
                        line = self.process.stdout.readline()
                        if line:
                            # Log R output to pipeline.log (don't duplicate here)
                            pass
                    except Exception as e:
                        self.log(f"Error reading process output: {e}")
                        break

                returncode = self.process.wait()
                self.log(f"R process exited with code {returncode}")

                if self.running:
                    self.log("Waiting 5s before restart...")
                    time.sleep(5)
                else:
                    self.log("Shutdown requested, not restarting")
                    break

            except FileNotFoundError:
                self.log("ERROR: Rscript not found. Is R installed?")
                self.log("Waiting 30s before retry...")
                time.sleep(30)
            except Exception as e:
                self.log(f"ERROR: {e}")
                self.log("Waiting 30s before retry...")
                time.sleep(30)

        self.log("Pipeline daemon stopped")

if __name__ == "__main__":
    daemon = PipelineDaemon()
    daemon.run()
