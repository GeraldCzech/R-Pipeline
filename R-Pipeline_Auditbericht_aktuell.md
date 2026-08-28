---
document_type: methodological_code_audit
schema_version: "2.0"
language: de
project: "Dissertation – Brand Equity und Spendenverhalten österreichischer NPOs"
repository: "https://github.com/GeraldCzech/R-Pipeline"
audited_commit: "0a059994400a0f74c49c8bccffbdc2358b2762c0"
baseline_commit: "eef6c657c87dfb90214065cfc3e1e42bf4d2ff73"
audit_date: "2026-08-28"
audit_type: delta_and_consolidated_audit
accepted_input_contract:
  dataset: FC_BO_orig
  dataset_status: validated_upstream
  unit_of_analysis: person_organisation_evaluation
  person_identifier: REF
  organisation_identifier: org
  raw_module_reconstruction_required: false
overall_status: NO_GO
status_reason: "Die Pipeline ist verbessert, aber Run-Isolation, Bayesian-Diagnostik, Gate-Konsistenz und Output-Provenienz sind nicht ausreichend umgesetzt."
closed_findings:
  - E-01
  - M-01
  - M-06
  - R-01
  - R-02
partially_closed_findings:
  - I-01
  - O-01
  - P-01
open_blockers:
  - B-01
  - B-02
  - B-03
  - B-04
  - P-01
---

# Auditbericht zur R-Pipeline – aktueller Stand

## Kurzurteil

Der neue Stand `0a05999` ist deutlich besser als `eef6c65`. Der Preflight prüft nun die richtige Masterdatei, unzureichender CFA-Fit wird nicht mehr automatisch durchgewinkt, der Abschlussbericht bezeichnet die Analyse korrekt als zweistufige CFA-/Mixed-Model-Analyse, die CFA-Kennzahlen werden nach Namen ausgewählt und die Freigabe ist grundsätzlich an ein Gate-Ergebnis gekoppelt.

Die Pipeline ist trotzdem noch nicht als wissenschaftlich freigegebene Analysepipeline einzustufen. Die wichtigsten verbliebenen Probleme sind nicht kosmetisch:

1. Das im Shell-Skript erzeugte laufbezogene Output-Verzeichnis wird von den R-Skripten nicht verwendet. Alte Ergebnisse können weiterhin in einen neuen Run eingehen.
2. Die Bayesian-Diagnostik berichtet weiterhin keine echten getrennten Bulk- und Tail-ESS und kann Divergenzen unzuverlässig als null erfassen.
3. Das Bayesian-Gate behauptet null tolerierte Divergenzen, lässt tatsächlich aber bis zu vier Divergenzen passieren.
4. Die erhöhte Samplingzahl wird in den gespeicherten Diagnosedaten mit den alten Zahlen dokumentiert.
5. Die LOO-Werte zweier verschiedener Outcomes werden weiterhin als Modellvergleich ausgegeben.

**Gesamtentscheidung: weiterhin NO-GO für automatische Freigabe oder ungeprüfte Übernahme in die Dissertation.** Ein kontrollierter Entwicklungsrun kann nach technischen Korrekturen sinnvoll sein; dessen Ergebnisse müssen anschließend separat auditiert werden.

## Was gegenüber dem letzten Audit behoben wurde

| Befund | Status | Bewertung |
|---|---|---|
| E-01: falscher Master-Dateiname im Preflight | behoben | Der Preflight prüft jetzt `AUDIT_RIGOROUS_MASTER_PIPELINE_CORRECTED.R` und die tatsächlich vorgesehenen R-Skripte. |
| M-01: unzureichender CFA-Fit wird als PASS gezählt | behoben | G4 erhöht bei Nichterfüllung jetzt `gates_failed` und stoppt die Freigabe. |
| M-06: falsche Bezeichnung als Multilevel-SEM | behoben | Der Bericht beschreibt nun eine zweistufige Analyse mit CFA-Faktorscores und gekreuzten Mixed Models. |
| R-01: CFA-Kennzahlen positionsabhängig falsch zugeordnet | behoben | CFI, TLI, RMSEA und SRMR werden nach ihrem Namen ausgewählt. |
| R-02: pauschal hart codiertes „READY FOR DISSERTATION“ | weitgehend behoben | Der Status wird aus `GATE_STATUS_REPORT.csv` gelesen und 2025 als explorativ bezeichnet. |
| P0-05: positionsabhängiger CFA-Score-Join | bereits zuvor behoben | `evaluation_id` wird für einen `left_join()` verwendet. |
| REF als Personen-ID | fachlich geklärt | `REF` ist im validierten `FC_BO_orig` die korrekte Personen-ID. |

Diese Änderungen sind substanziell und sollten beibehalten werden.

## Verbindlicher Inputvertrag

Die Pipeline darf direkt mit `FC_BO_orig` arbeiten. Sie muss die ursprünglichen SoSciSurvey-Module nicht neu zusammensetzen.

```yaml
analysis_input:
  object: FC_BO_orig
  status: validated_upstream_dataset
  unit: person_organisation_evaluation
  person_id: REF
  organisation_id: org
  reconstruct_start01_and_questionnaire_modules: false
```

Die Datei `01_PERSON_ID_RECONSTRUCTION.R` rekonstruiert daher fachlich keine Person-ID. Sie validiert und übernimmt die bereits etablierte Personen- und Organisationsstruktur. Eine Umbenennung in `01_ANALYSIS_ID_VALIDATION.R` wäre sachlich klarer, ist aber kein statistischer Blocker.

## Offene Befunde

### P-01 – Die Run-Isolation ist nur im Shell-Skript vorhanden

**Schweregrad:** Blocker für Reproduzierbarkeit

Das Shell-Skript erzeugt:

```bash
OUTPUT_DIR="${BASE_DIR}/AUDIT_PIPELINE_OUTPUTS/RUN_${RUN_ID}"
```

Die R-Skripte erhalten dieses Verzeichnis jedoch nicht. Master, CFA/GLMM, Bayesian-Phase und Abschlussbericht verwenden weiterhin:

```r
output_base <- file.path(here::here(), config$analysis$base_dir)
```

mit:

```yaml
analysis:
  base_dir: AUDIT_PIPELINE_OUTPUTS
```

`01_PERSON_ID_RECONSTRUCTION.R`, `01_ANALYSIS_INPUT_VALIDATION.R` und `RUN_GATES.R` schreiben sogar weiterhin direkt nach `/home/gerald/R-pipeline/AUDIT_PIPELINE_OUTPUTS`.

**Folge:** Das neue `RUN_<timestamp>_<commit>`-Verzeichnis bleibt leer, während die Analyse in den alten gemeinsamen Outputordner schreibt. G1 kann dadurch Dateien eines früheren Runs akzeptieren.

**Erforderliche Korrektur:** Der Orchestrator muss `RUN_OUTPUT_DIR` als Umgebungsvariable oder Kommandozeilenargument an jedes R-Skript übergeben. Jedes Skript und jedes Gate muss ausschließlich dieses Verzeichnis verwenden.

Beispiel:

```bash
export RUN_OUTPUT_DIR="$OUTPUT_DIR"
Rscript "${BASE_DIR}/AUDIT_RIGOROUS_MASTER_PIPELINE_CORRECTED.R"
```

```r
output_base <- Sys.getenv("RUN_OUTPUT_DIR")
stopifnot(nzchar(output_base))
```

### I-01 – Portable Pfade sind nur teilweise umgesetzt

**Schweregrad:** schwerwiegend

`here()` und `config.yml` wurden in mehreren Hauptphasen eingeführt. Weiterhin fest codiert sind jedoch unter anderem:

- `/home/gerald/R-pipeline` im Orchestrator, Preflight und `RUN_GATES.R`;
- `/home/gerald/10787172/fragebogen_cache_v5.rds` im Preflight, in `01_PERSON_ID_RECONSTRUCTION.R` und in `config.yml`;
- globale Outputpfade in beiden vorgeschalteten Validierungsmodulen.

Eine absolute Inputdatei in einer lokalen, nicht versionierten Konfiguration kann zulässig sein. Sie sollte aber nicht in der versionierten Standardkonfiguration festgeschrieben werden. Empfehlenswert ist eine lokale Konfiguration oder eine Umgebungsvariable mit expliziter Fehlermeldung.

**Status:** teilweise behoben, nicht geschlossen.

### O-01 – Outcome-Modul wurde nur umbenannt

**Schweregrad:** Dokumentations- und Provenienzproblem

`02_OUTCOME_PARSER.R` wurde ohne Inhaltsänderung in `01_ANALYSIS_INPUT_VALIDATION.R` umbenannt. Header, Konsolenausgaben, Variablennamen und Outputdateien sprechen weiterhin von „Parser“, „raw value“ und `02_OUTCOME_PARSER_OUTPUT.rds`.

Da `FC_BO_orig` als valider vorgelagerter Datensatz bestätigt ist, muss die Pipeline `OF02_02` nicht erneut parsen. Sie sollte aber korrekt dokumentieren:

> `OF02_02_num` is a validated upstream variable contained in `FC_BO_orig`. This module validates its type and admissible range; it does not reconstruct the original free-text transformation.

**Status:** nur kosmetisch teilweise behoben.

### B-01 – Bulk-ESS und Tail-ESS sind weiterhin nicht getrennt berechnet

**Schweregrad:** wissenschaftlicher Blocker für den behaupteten Bayesian Workflow

In `AUDIT_RIGOROUS_PHASE_8_9_BAYESIAN.R`, Zeilen 95–110, werden beide Kennzahlen weiterhin aus demselben Ausdruck erzeugt:

```r
min(neff_ratio(bayes_binary)) * 4000
```

Die Zeilen werden lediglich als „Bulk_ESS“ und „Tail_ESS“ bezeichnet. Beide Statuswerte sind weiterhin hart auf `✓` gesetzt. Die Commit-Historie bezeichnet dies zeitweise als behoben, der finale Code enthält die alte Logik jedoch weiterhin.

**Erforderliche Korrektur:** echte `ess_bulk`- und `ess_tail`-Werte aus den Posterior-Draws extrahieren, Mindestwerte speichern und Gate-Status aus diesen Werten ableiten. Wenn brms die Werte nur im gedruckten Summary zeigt, reicht das nicht für einen maschinenlesbaren Gate-Report.

### B-02 – Divergenzdiagnostik ist weiterhin unzuverlässig

**Schweregrad:** wissenschaftlicher Blocker

Divergenzen werden über folgende interne Objektstruktur abgefragt:

```r
bayes_binary$fit@sim$divergences[[1]]
```

Diese Abfrage ist nicht als robuste backendunabhängige Diagnostikschnittstelle abgesichert. Bei fehlendem Element kann `sum(NULL)` null ergeben und dadurch fälschlich keine Divergenzen melden.

Weiterhin fehlen:

- Max-Treedepth-Überschreitungen;
- E-BFMI;
- MCSE;
- Pareto-\(k\)-Zusammenfassung;
- ein maschinenlesbarer PPC-Befund.

Mehr Iterationen lösen diese konzeptionellen Diagnoseprobleme nicht.

### B-03 – Das Bayesian-Gate widerspricht sich weiterhin

**Schweregrad:** Freigabeblocker

Der Code zeigt mehrfach die Regel `Divergences = 0` an. Für die Freigabe verwendet er jedoch:

```r
div_ok <- all(bayes_diag$divergences < 5)
```

Damit bestehen Modelle mit ein bis vier Divergenzen das Gate. Der Kommentar „no divergences tolerated“ widerspricht dem ausgeführten Code.

**Erforderliche Korrektur:** Wenn die Regel null Divergenzen lautet, muss der Test exakt sein:

```r
div_ok <- all(bayes_diag$divergences == 0)
```

Zudem müssen R-hat und Divergenzen auf fehlende oder nicht endliche Werte geprüft werden. Ein `NA` darf niemals zu einem impliziten PASS führen.

### B-04 – Gespeicherte Sampling-Metadaten sind falsch

**Schweregrad:** Ergebnisprovenienz und Berichtskonsistenz

Die Modelle wurden auf folgende Sollwerte umgestellt:

```text
4 Chains × 4.000 Iterationen, davon 2.000 Warmup
8.000 Post-Warmup-Draws insgesamt
```

`diag_report` speichert weiterhin:

```r
n_warmup = 1000
n_post_samples = 4000
```

Der Abschlussbericht nennt ebenfalls weiterhin die früheren Samplingangaben. Damit widersprechen Modellcode, Diagnostikdatei und Bericht einander.

**Erforderliche Korrektur:** Samplingmetadaten direkt aus den Fitobjekten oder aus einer einzigen Konfiguration ableiten; niemals parallel hart codieren.

### B-05 – Priors werden falsch bezeichnet

**Schweregrad:** Berichtskorrektur

Der Bericht bezeichnet die Priors als Student-\(t\)-Priors. Tatsächlich verwendet der Code Normalverteilungen für Regressionskoeffizienten, Intercept und Random-Effects-Standardabweichungen sowie eine Exponentialverteilung für `sigma`.

Die Bezeichnung muss den tatsächlich gesetzten Priors entsprechen. Zusätzlich fehlt weiterhin ein Prior-Predictive-Check.

### B-06 – Unterschiedliche Outcomes werden weiterhin als LOO-Modellvergleich geführt

**Schweregrad:** methodisch schwerwiegend

Die Datei `09_LOO_MODEL_COMPARISON.csv` enthält das binäre Spendenmodell und das Betragsmodell. Diese Modelle beziehen sich auf unterschiedliche Zielvariablen und unterschiedliche Analysestichproben. Ihre ELPD-/LOOIC-Werte sind nicht als relativer Modellvergleich interpretierbar.

**Erforderliche Korrektur:** LOO-Diagnostik getrennt je Outcome speichern. Modellvergleiche nur zwischen alternativen Spezifikationen desselben Outcomes auf identischer Beobachtungsmenge durchführen.

### G-01 – Es gibt weiterhin nur fünf statt zehn implementierte Gates

**Schweregrad:** Dokumentations- und Kontrollproblem

`RUN_GATES.R` behauptet G1–G10, implementiert aber nur G1–G5. Es fehlen eigenständige Gates für:

- Run-Provenienz und aktuelle Dateizeitstempel;
- frequentistische Konvergenz und Singularität;
- ESS/NUTS-Diagnostik;
- posterior-prädiktive Prüfung und Pareto-\(k\);
- Berichtskonsistenz.

Die Zahl der Gates sollte nicht behauptet werden, bevor sie tatsächlich umgesetzt ist.

### G-02 – Starre CFA-Cutoffs werden als „published standards“ dargestellt

**Schweregrad:** methodische Präzisierung

Die Änderung, unzureichenden Fit nicht mehr automatisch passieren zu lassen, ist richtig. Die Aussage, CFI > .95 und RMSEA < .08 seien zwingende „published standards“, ist jedoch zu schematisch. Fitindizes sind gemeinsam, modell- und datenkontextbezogen zu interpretieren. Insbesondere sollten SRMR, TLI, Stichprobengröße, Freiheitsgrade, Residuen und substanzielle Plausibilität berücksichtigt werden.

Für ein automatisches Gate ist eine vorab dokumentierte Entscheidungsregel sinnvoll; sie sollte aber als projektspezifische Freigaberegel und nicht als universelle wissenschaftliche Wahrheit bezeichnet werden.

### R-03 – Bericht wird vor der Gate-Statusprüfung geschrieben

**Schweregrad:** schwerwiegend bei manueller Ausführung

`AUDIT_RIGOROUS_PHASE_10_FINAL_REPORT.R` erzeugt und speichert den Bericht, bevor `GATE_STATUS_REPORT.csv` gelesen wird. Im Orchestrator wird Phase 10 nach einem fehlgeschlagenen Gate zwar nicht aufgerufen. Bei manueller Ausführung kann jedoch bereits ein Bericht entstehen, obwohl kein aktuelles Gate-Ergebnis vorhanden ist.

Der Fallback bei fehlendem Gate-Report lautet zudem `exploratory_only` statt `blocked`. Fail-safe wäre:

```r
release_status <- "blocked"
```

Die Gate-Prüfung muss an den Anfang von Phase 10 und vor jedes Schreiben eines Berichts.

### R-04 – Statusspalte im Master Summary bleibt hart auf Erfolg gesetzt

**Schweregrad:** Ergebnisdarstellung

Obwohl der globale Freigabestatus verbessert wurde, setzt `MASTER_SUMMARY.csv` weiterhin für alle 14 Einträge pauschal `✓`. Das ist beispielsweise bei nicht bestandenen oder nicht berechneten Bayesian-Diagnosen falsch.

Jede Zeile muss ihren Status aus der jeweiligen Kennzahl und ihrer Regel ableiten oder ohne Statussymbol berichtet werden.

### P-02 – Reproduzierbarkeit bleibt unvollständig

**Schweregrad:** wissenschaftliche Dokumentation

Weiterhin fehlen:

- `renv.lock` oder eine gleichwertige Paketfixierung;
- vollständiges `sessionInfo()` als Datei;
- Run-Manifest mit Commit-Hash und Skriptprüfsummen;
- aktuelle Outputs des neuen Codes;
- nachvollziehbarer Nachweis, dass alle Dateien eines Berichts demselben Run entstammen.

Der Claim „all code and results in version control“ bleibt daher falsch. Präziser wäre:

> Analysis code is version-controlled. The validated input dataset and generated outputs are stored separately and identified through checksums and run manifests.

## Statistische Gesamtbewertung

Die grundlegende Analysearchitektur ist für eine explorative Discovery-Analyse plausibel:

- valider Person-Organisation-Datensatz `FC_BO_orig`;
- `REF` als Personen-ID;
- ordinale CFA mit WLSMV;
- schlüsselbasierte Zuordnung der Faktorscores;
- getrennte Modelle für Spendenentscheidung und positive Spendenhöhe;
- gekreuzte Random Intercepts für Person und Organisation;
- vorsichtige Kennzeichnung der 2025-Daten als explorativ.

Sie ist keine gemeinsame SEM-Schätzung. Die zweistufige Verwendung von Faktorscores überträgt die Messunsicherheit nicht in die Outcome-Modelle. Das ist für Exploration vertretbar, muss aber als Limitation erhalten bleiben.

Die Erhöhung der Bayesian-Iterationen ist kein Ersatz für valide Priors, korrekte Diagnostik oder Modellrevision. Erst ein vollständiger Run mit echten Posterior- und NUTS-Diagnosen erlaubt eine Aussage zur Konvergenz.

## Priorisierter Reparaturplan

### P0 – vor dem nächsten vollständigen Run

1. `RUN_OUTPUT_DIR` an jedes R-Skript übergeben und ausschließlich dieses Verzeichnis verwenden.
2. G1 auf Dateien des aktuellen Runs, Commit-Hash und Zeitstempel beschränken.
3. Divergenzen robust extrahieren und das Gate exakt auf null Divergenzen setzen.
4. Echte Bulk- und Tail-ESS maschinenlesbar erzeugen und gaten.
5. Samplingmetadaten aus Fit oder Konfiguration ableiten.
6. Gate-Status vor der Berichtserzeugung prüfen; fehlender Status muss `blocked` bedeuten.
7. LOO-Ergebnisse nach Outcome trennen.

### P1 – vor Ergebnisinterpretation

1. Max-Treedepth, E-BFMI, MCSE und Pareto-\(k\) ergänzen.
2. Prior-Predictive-Checks ergänzen.
3. Frequentistische Singularität und Clusterstabilität als Gate aufnehmen.
4. CFA-Entscheidungsregel als projektspezifische Regel dokumentieren und mehrere Fitinformationen berücksichtigen.
5. Ergebnisstatus je Tabellenzeile berechnen oder Statusspalte entfernen.
6. Outcome-Modul inhaltlich als Validierung der vorgelagerten Variable dokumentieren.

### P2 – vor Dissertationseinbindung

1. Paketumgebung fixieren und vollständiges `sessionInfo()` speichern.
2. Run-Manifest mit Input-, Skript- und Outputprüfsummen erzeugen.
3. README, Auditstatus und tatsächlichen Code automatisch auf Konsistenz prüfen.
4. 2025 ausschließlich explorativ und assoziativ formulieren.
5. Modellspezifikationen für die konfirmatorische 2026-Analyse vorab fixieren.

## Abnahmeentscheidung

| Freigabestufe | Aktueller Status |
|---|---|
| statischer Codefortschritt | deutlich verbessert |
| kontrollierter Entwicklungsrun | nach P0-Korrekturen sinnvoll |
| explorative Ergebnisfreigabe | noch nicht |
| ungeprüfte Dissertationseinbindung | nein |
| konfirmatorische Evidenz | nein; 2026-Sample erforderlich |

## Maschinenlesbares aktuelles Befundregister

```yaml
audit_result:
  commit: 0a059994400a0f74c49c8bccffbdc2358b2762c0
  decision: NO_GO
  input_contract_valid: true
  ref_is_person_id: true
  two_stage_model_label_corrected: true

findings:
  - id: E-01
    status: closed
    evidence: "Preflight now parses the corrected master script"

  - id: M-01
    status: closed
    evidence: "Failed CFA rule increments gates_failed"

  - id: M-06
    status: closed
    evidence: "Final report labels analysis as two-stage CFA-score mixed model"

  - id: R-01
    status: closed
    evidence: "CFA indices selected by name"

  - id: P-01
    status: open
    severity: blocker
    evidence: "Shell RUN_OUTPUT_DIR is not consumed by R scripts"

  - id: B-01
    status: open
    severity: blocker
    evidence: "Bulk and tail ESS use the same neff_ratio expression"

  - id: B-02
    status: open
    severity: blocker
    evidence: "Divergences are extracted from a fragile internal slot"

  - id: B-03
    status: open
    severity: blocker
    evidence: "Gate advertises zero divergences but tests divergences < 5"

  - id: B-04
    status: open
    severity: blocker
    evidence: "Fit uses warmup 2000 and 8000 post-warmup draws; diagnostic table reports 1000 and 4000"

  - id: B-06
    status: open
    severity: major
    evidence: "LOO values for different outcomes are labeled model comparison"

  - id: G-01
    status: open
    severity: major
    evidence: "Only G1-G5 are implemented despite claim G1-G10"

  - id: R-03
    status: open
    severity: blocker
    evidence: "Report is written before gate status is checked; missing gate defaults to exploratory"

next_release_state: exploratory_only
required_before_next_release_state:
  - isolate_outputs_by_run
  - validate_current_run_provenance
  - implement_real_bulk_and_tail_ess
  - robustly_extract_nuts_diagnostics
  - require_zero_divergences
  - correct_sampling_metadata
  - check_gate_before_reporting
  - audit_complete_run_outputs
```

## Schlussfolgerung

Das Update schließt mehrere relevante Befunde und verbessert die wissenschaftliche Selbstbegrenzung der Pipeline. Die aktuelle Commit-Botschaft „All 10 audit findings verified and fixed“ ist dennoch nicht zutreffend. Besonders Run-Isolation und Bayesian-Diagnostik sind im ausgeführten Code nicht so umgesetzt, wie es die Dokumentation behauptet.

Nach den sieben P0-Schritten sollte ein vollständiger Run in einem leeren, commitgebundenen Outputverzeichnis durchgeführt werden. Erst die dabei neu erzeugten CSV-, RDS-, Diagnose- und Logdateien bilden die Grundlage für den nächsten numerischen Ergebnis-Audit.
