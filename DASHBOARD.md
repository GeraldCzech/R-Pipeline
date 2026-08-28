# R-Pipeline Web Dashboard

Ein modernes Web-Dashboard zur Echtzeit-Überwachung deiner R-Pipeline-Berechnungen. Öffne einfach `http://localhost:5000` im Browser — vollständig unabhängig vom Terminal!

## Features

- 📊 **Live Pipeline Status** — Ist die Pipeline aktiv?
- 🎯 **Target Progress** — Welche Berechnungen sind fertig?
- 💻 **Resource Monitoring** — CPU und Memory-Auslastung
- 📁 **Verfügbare Ergebnisse** — Welche Output-Dateien gibt es?
- 🔍 **Live Logs** — Aktuelle Pipeline-Aktivität
- ⚡ **Auto-Refresh** — Aktualisiert alle 5 Sekunden

## Installation

### 1. Python Dependencies
```bash
pip install flask psutil
```

### 2. Systemd Service registrieren
```bash
sudo bash /home/gerald/R-pipeline/install_dashboard.sh
```

Das installiert den Service und startet das Dashboard automatisch.

## Zugriff

**Im Browser:**
```
http://localhost:5000
```

Oder vom anderen Computer im Netzwerk:
```
http://<your-ip>:5000
```

## Dashboard Übersicht

### Status Card
- **Service Status** — Läuft die Pipeline gerade?
- Auto-Refresh Indikator

### Berechnete Targets
- Fortschrittsanzeige (Prozent)
- Anzahl fertiggestellter Targets
- Visuelle Progress Bar

### Ressourcen
- **CPU-Auslastung** — Wie viel CPU braucht die aktuelle Berechnung?
- **Speichernutzung** — RAM-Verbrauch
- **Status** — Ob R gerade aktiv ist

### Tabs

#### 1. **Targets** 
Alle gecachten Berechnungen:
- `block1_data`, `admin_data`, `evid_corpus` — Eingangsdaten
- `bsem_*` — Bayesian SEM Modelle
- `robma_*` — Robust Meta-Analysis
- `bayes_mev_*` — Bayesian Multilevel Models
- `dominance_results`, `nca_results`, `elasticnet_results` — Weitere Analysen

#### 2. **Ergebnisse**
Verfügbare Output-Dateien mit:
- Dateiname
- Dateigröße
- Erstellungsdatum

#### 3. **Logs**
Letzte 30 Log-Zeilen aus der Pipeline:
- Normale Logs (grau)
- Fehler (rot)
- Erfolgsmeldungen (grün)

## Verwaltung

### Dashboard starten
```bash
sudo systemctl start r-pipeline-dashboard
```

### Dashboard stoppen
```bash
sudo systemctl stop r-pipeline-dashboard
```

### Status checken
```bash
systemctl status r-pipeline-dashboard
```

### Live Logs des Dashboards
```bash
journalctl -u r-pipeline-dashboard -f
```

### Neu starten
```bash
sudo systemctl restart r-pipeline-dashboard
```

## API Endpoints

Das Dashboard nutzt folgende APIs (falls du programmatischen Zugriff brauchst):

- `GET /api/status` — Kompletter Status
- `GET /api/pipeline` — Nur Pipeline-Status
- `GET /api/targets` — Nur Targets
- `GET /api/resources` — Nur Ressourcen
- `GET /api/logs` — Nur Logs
- `GET /api/results` — Nur Ergebnisse

Beispiel:
```bash
curl http://localhost:5000/api/status | jq .
```

## Troubleshooting

### Dashboard startet nicht

```bash
# Logs checken
journalctl -u r-pipeline-dashboard -n 50

# Flask Port belegt?
lsof -i :5000

# Manuell testen
python3 /home/gerald/R-pipeline/dashboard_app.py
```

### Flask/psutil nicht installiert

```bash
pip install flask psutil
sudo systemctl restart r-pipeline-dashboard
```

### Browser zeigt "Connection refused"

1. Ist der Service aktiv?
   ```bash
   systemctl status r-pipeline-dashboard
   ```

2. Läuft auf Port 5000?
   ```bash
   lsof -i :5000
   ```

3. Firewall blockiert Port 5000?
   ```bash
   sudo ufw allow 5000
   ```

## Auto-Start on Boot

Der Service ist bereits für Auto-Start konfiguriert:

```bash
# Prüfen
sudo systemctl is-enabled r-pipeline-dashboard

# Deaktivieren
sudo systemctl disable r-pipeline-dashboard

# Wieder aktivieren
sudo systemctl enable r-pipeline-dashboard
```

## Performance

Das Dashboard ist sehr leicht:
- **Python Flask** — Minimal Overhead
- **Auto-Refresh alle 5s** — Nicht mehr als nötig
- **RAM-Limit: 256MB** — Kann nicht über diesen Wert gehen
- **Nur Datei-Lesen** — Keine Schreibvorgänge

## Sicherheit

Das Dashboard läuft nur lokal (localhost:5000). Für externen Zugriff:

```bash
# Mit Nginx reverse proxy + SSL
# Oder: SSH Port Forwarding
ssh -L 5000:localhost:5000 user@your-server
```

## Nächste Schritte

1. **Dashboard installieren:**
   ```bash
   sudo bash /home/gerald/R-pipeline/install_dashboard.sh
   ```

2. **Im Browser öffnen:**
   ```
   http://localhost:5000
   ```

3. **Pipeline starten:**
   ```bash
   sudo systemctl restart r-pipeline
   ```

4. **Beobachten wie die Targets berechnet werden!**

Viel Spaß! 🚀
