# R‑Pipeline: rigorose Dissertations- und Ergebnisaudit

**Auditdatum:** 26. August 2026  
**Repository:** <https://github.com/GeraldCzech/R-Pipeline>  
**Geprüfter Remote-Stand:** `origin/main` bei Commit `7cea09def3fb1c9ac209bd5e86cbaff12d74227c`  
**Vergleichsstand des vorigen Audits:** `1310af1`  
**Neue Commits:** `ba576d8` und `7cea09d`  
**Audittyp:** statische Codeprüfung, vollständige Ergebnisinventur, Rohdaten-/Codebuchabgleich, Berichtskonsistenz und Beurteilung der Aussagekraft für eine Dissertation  
**Wichtig:** Das Repo enthält die für die Pipeline erwartete RDS-Eingabedatei nicht. Eine vollständige Reproduktion war daher nicht möglich. Diese Audit trennt strikt zwischen *vorhandener Evidenz*, *statisch nachvollziehbarer Berechnung* und *bloßen Berichtsaussagen*.

---

## 1. Gesamturteil

### 1.1 Kurzurteil

Der aktuelle Stand ist **nicht „publication-ready“ und nicht als konfirmatorische Hauptanalyse einer Dissertation freigabefähig**. Er ist als explorative Entwicklungs- und Discovery-Pipeline nutzbar, enthält aber mehrere Befunde, die derzeit nicht berichtet oder integriert werden dürfen.

Das stärkste belastbare Ergebnis bleibt die **vergleichsweise gute psychometrische Leistung des reduzierten Boenigk-Modells für Trust und Commitment**. Dagegen sind die neuen Aussagen über einen bestätigten kausalen Pfad bis zur Spende, acht signifikante Moderationen, Größenmoderation, volle Messinvarianz, dramatische Random-Slope-Heterogenität und 160.000 konsistente Bayesian-Posteriorziehungen nicht hinreichend belegt oder nachweislich falsch dargestellt.

### 1.2 Ampel

| Bereich | Urteil | Begründung |
|---|---:|---|
| Skalenanalyse / Messmodelle | **Gelb–Grün** | Gute Evidenz für Trust/Commitment; Faircloth und Romero zeigen Misfit bzw. Diskriminanzprobleme. Modellversionen und Stichproben müssen vereinheitlicht werden. |
| Rohdatenprovenienz / Analyseeinheit | **Rot** | 2.038 werden als Personen bezeichnet, obwohl Rohdatei und Erhebungsdesign modulare, wiederholte Organisationsbewertungen zeigen; `person_id = row_number()` löst das Problem nicht. |
| Outcome-Definition | **Gelb–Rot** | Die neue Hurdle-Logik mit Jahresbetrag ist konzeptionell besser. Die notwendige Bereinigung, Zuordnung und Validierung des selbstberichteten Geldtexts ist aber nicht reproduzierbar. Alte Resultate verwenden weiterhin ungültige Outcomes. |
| Frequentistische Outcome-Modelle | **Rot** | Im neuen Ergebnisordner fehlen vollständige Koeffiziententabellen, Unsicherheit, N je Modell und Diagnostik. Berichtskoeffizienten sind nicht durch gespeicherte Outputs belegt. |
| Bayesian GLM | **Rot** | Nur fünf Diagnosezeilen gespeichert; keine neuen Posteriorziehungen, Parameterschätzungen, PPC/LOO oder Samplerdiagnostik. Alte Draws gehören zu einem anderen Outcome. |
| Bayesian SEM | **Rot** | „Comparison“-CSV enthält nur Modellnamen und „Complete“; keine Posteriorparameter, R-hat/ESS, Priors, Fitmaße oder Modellvergleiche. Bericht meldet zugleich Divergenzen. |
| Moderation | **Rot** | `Significant=TRUE` wird im Code bei erfolgreichem Fit gesetzt, nicht anhand eines Tests. Mehrere Moderatoren sind endogen oder falsch benannt. |
| Messinvarianz | **Rot** | Die gespeicherte Invarianzanalyse ist fehlgeschlagen. |
| Random Slopes / Heterogenität | **Rot–Gelb** | Varianzpunktschätzungen ohne CI, Singularity-/Konvergenzprüfung oder Modellvergleich; nur 25 stark ungleich besetzte Cluster. |
| Reproduzierbarkeit | **Rot** | Eingabe-RDS, Erzeugungsskript, Lockfile, Sessioninfo, Modellobjekte, Logs und neue Draws fehlen; absolute lokale Pfade. |
| Berichtswesen | **Rot** | Executive Summary widerspricht Dateien, Code, Working Paper und eigenen Limitationen. |

### 1.3 Freigabeentscheidung

**Nicht freigeben:**

- „The analysis is publication-ready“;
- „all 13 phases successful“;
- „full invariance supported“;
- „all eight moderations significant“;
- „all results robust across organisation size“;
- kausale Formulierungen wie „trust and commitment drive donations“ oder „pathway confirmed“;
- die Zahl „2.038 individuals“ ohne eindeutige Personenrekonstruktion;
- die Behauptung, 160.000 Posteriorziehungen hätten denselben strukturellen Befund bestätigt.

**Vorläufig integrierbar:**

- psychometrischer Modellvergleich als Discovery-Befund;
- gute Reliabilität und konvergente Validität der Trust-/Commitment-Skalen;
- deskriptive, klar als nicht kausal bezeichnete Assoziation von Commitment mit Spendenmaßen;
- die starke organisatorische Ungleichverteilung als Design- und Generalisierbarkeitsbefund;
- der Befund, dass mehrere ältere Modellierungen und Outcomes verworfen werden müssen.

---

## 2. Auditumfang und Evidenzstandard

### 2.1 Geprüfte Materialien

**Repo**

- alle R-Skripte im Root;
- alle Markdown-Berichte;
- alle 26 CSV-Dateien unter `v2_pipeline/`;
- neue Dateien aus den Commits `ba576d8` und `7cea09d`;
- Abgleich von Code, erzeugten Dateinamen und narrativen Claims.

**Hochgeladene Primär- und Berichtsmaterialien**

1. Skalen-/Variablen-Codebuch (`.xlsx`);
2. Skalenanalyse-Ergebnistext (`.txt`);
3. rohe SoSciSurvey-Exportdatei (`.csv`/tab-separiert);
4. Zusammenfassung der Skalenanalyse (`.docx`);
5. Proposal (`.pdf`);
6. ERNOP-Workshoppapier (`.pdf`);
7. Working Paper, Version 09/2025 (`.docx`).

### 2.2 Evidenzklassen

| Klasse | Definition | Zulässige Nutzung |
|---|---|---|
| **A** | Rohdaten + vollständiger Transformationscode + Modellcode + gespeichertes Modell/komplette Outputs + Diagnostik stimmen überein | Haupttext, sofern Design und Modell angemessen sind |
| **B** | Berechnung ist aus Daten und Code nachvollziehbar, aber einzelne Reproduktionsartefakte fehlen | Explorativ oder nach Ergänzung |
| **C** | Nur Ergebnis-CSV oder Bericht, ohne vollständige Provenienz/Diagnostik | Nicht als Hauptbefund; höchstens Arbeitsnotiz |
| **D** | Narrativ/hart codierter Status widerspricht Code oder Datei | Nicht verwenden |

Im aktuellen Repo erreicht **kein neuer Outcome-/Moderations-/Bayes-Befund Klasse A**.

### 2.3 Grenzen der Audit

- Das Repo enthält `pipeline_data_fc_bo_with_ordinal_awareness.rds` nicht.
- Es fehlt der vollständige Code, der die hochgeladene Rohdatei in dieses RDS überführt.
- Die lokale Prüfungsumgebung enthält kein R; eine erneute Modellausführung war zusätzlich nicht möglich. Dieser Punkt wäre bei vorhandener RDS-Datei technisch behebbar, der fehlende Input bleibt aber der primäre Reproduktionsblocker.
- Statische Codebefunde, CSV-Inhalte und Widersprüche sind davon nicht betroffen.

---

## 3. Was sich im neuen Repo-Stand geändert hat

Die zwei neuen Commits fügen eine umfassende 13-Phasen-Narration hinzu:

- `COMPREHENSIVE_CORRECTED_PIPELINE.R`;
- `PHASE_10_13_COMPLETION.R`;
- `PHASE_11_13_ROBUST.R`;
- Überarbeitung von `REBUILT_PIPELINE_COMPLETE.R`;
- neue Ergebnisordner `COMPREHENSIVE_RESULTS` und `CORRECTED_ANALYSIS`;
- neue Executive Summary und Bayesian Detailed Report.

Positiv ist die **Trennung von Messmodell, manifesten Multilevel-Modellen und Hurdle-Outcomes**. Damit werden zwei frühere Kernfehler zumindest konzeptionell adressiert:

1. `OF01` wird nicht mehr als Spendenintention behandelt;
2. `OF02_Freq` wird in der neuen Hauptpipeline nicht mehr als echte Frequenz verwendet;
3. die ungültige Kombination `cluster=` + ordinales WLSMV wird im überarbeiteten Hauptteil durch manifeste Mixed Models ersetzt.

Diese Korrekturen sind wichtig, aber die neu hinzugefügten Phasen 8–13 führen gleichzeitig neue, teilweise schwerere Dokumentations- und Inferenzfehler ein.

---

## 4. Rohdaten- und Analyseeinheitsaudit

### 4.1 Direkt beobachtete Struktur der hochgeladenen Rohdatei

Die Datei `rdata_SpendenOrganisationen_2025-05-16_19-44.csv` ist tab-separiert und umfasst:

- **1.803 Zeilen × 271 Variablen**;
- `CASE`: 1.803 nicht fehlende, eindeutige Werte;
- `SERIAL`: vollständig leer;
- `REF`: 1.788 nicht fehlende Werte, aber nur 519 verschiedene Werte;
- fünf Fragebogenmodule:
  - `Start01`: 503;
  - `qnr1`: 450;
  - `qnr2`: 439;
  - `qnr5`: 209;
  - `qnr4`: 202.

Die Markenitems `B101_*` und `B102_*` kommen jeweils nur in **652** Rohzeilen vor. Die Geldvariablen sind Textfelder und liegen nur in 469–510 Rohzeilen vor. Das ist keine rechteckige Personenstichprobe, sondern ein modularer Export.

### 4.2 Personen, Module und Organisationsbewertungen

Das Working Paper beschreibt ausdrücklich:

- ein Startmodul;
- zufällige Zuweisung zu `QNR1` oder `QNR2`;
- optionale Follow-ups `QNR4`/`QNR5`;
- eine zweite, aus bekannten Organisationen zufällig ausgewählte Organisationsbewertung;
- innerhalb derselben Person mehrere Marken-/Organisationsurteile.

Die neue Pipeline setzt dagegen in allen zentralen Skripten:

```r
person_id = row_number()
```

Das erzeugt nur eine eindeutige **Zeilen-ID**, keine Personen-ID. Es verhindert daher weder Pseudoreplikation noch die Unterschätzung von Standardfehlern bei wiederholten Bewertungen.

### 4.3 Unaufgelöste Fallzahldiskrepanzen

| Quelle | Bezeichnung | Zahl |
|---|---|---:|
| Rohdatei | Zeilen/Module | 1.803 |
| Rohdatei | `Start01` | 503 |
| Rohdatei | verschiedene `REF` | 519 |
| Working Paper, Einladungstabelle | „Survey Respondents“ | 1.571 |
| Working Paper, Demografietabelle | total | 1.087 |
| Working Paper / neue Pipeline | „respondents/persons“ | 2.038 |
| ältere Modelloutputs | analysierte Organisationsbewertungen | 1.337 |
| neue Sensitivitäts-CSV | Summe N | 1.336 |

Diese Zahlen können aus unterschiedlichen Filter-, Modul- und Long-Form-Datensätzen stammen. Im Repo fehlt jedoch eine Fallfluss-Tabelle, die jeden Übergang erklärt. Daher darf `N=2.038` derzeit nicht als Zahl unabhängiger Personen berichtet werden.

### 4.4 Erforderliche Korrektur

Es braucht eine reproduzierbare Crosswalk-Tabelle mit mindestens:

- `person_id_real`;
- `module_case_id`;
- `parent_ref`;
- `evaluation_id`;
- `org_id`;
- `source_sample`;
- `questionnaire_module`;
- Einschluss-/Ausschlussgrund;
- Indikator, ob erste oder zweite Organisationsbewertung.

Danach müssen Modelle mindestens **Bewertungen in Personen und Personen in Organisationen** berücksichtigen. Je nach tatsächlicher Struktur ist das ein dreistufiges oder cross-classified Modell; `row_number()` ist keine Lösung.

### 4.5 Missing Codes und Datentypen

Im Codebuch sind für Likert-Items unter anderem `-9 = nicht beantwortet` dokumentiert. Die neue Pipeline macht unmittelbar `as.numeric()` und `rowMeans()`. Da das vorgelagerte RDS nicht vorhanden ist, ist nicht prüfbar, ob `-9` zuvor in `NA` umkodiert wurde. Falls nicht, wird `-9` als reale extreme Antwort verarbeitet und sogar als ordinale Kategorie an WLSMV übergeben.

**Pflichtprüfung:** Vor jeder Skalierung müssen alle Missing-/Filtercodes (`-9`, `-1` und gegebenenfalls weitere) anhand des Codebuchs explizit umkodiert und in einem Recode-Log dokumentiert werden.

---

## 5. Audit der Messung und Skalenberichte

### 5.1 Belastbare Skalenbefunde

Die hochgeladene Skalen-Zusammenfassung berichtet:

| Modell | CFI | TLI | RMSEA | SRMR | Auditbewertung |
|---|---:|---:|---:|---:|---|
| Faircloth | .895 | .881 | .083 | .071 | kein überzeugender globaler Fit; `FC_BI` AVE ≈ .36 |
| Boenigk | .994 | .989 | .067 | .022 | insgesamt stark; sehr hohe Ladungen/Reliabilität, aber Modellversion präzisieren |
| Romero | .859 | .841 | .095 | .077 | deutlicher Misfit und konzeptuelle Überlappungen |

Trust und Commitment im Boenigk-Modell zeigen hohe interne Konsistenz und AVE. Das ist der stärkste derzeit integrierbare empirische Befund.

### 5.2 Mehrere nicht harmonisierte Modellversionen

Für scheinbar ähnliche Modelle werden unterschiedliche Fitwerte berichtet:

- Skalen-Zusammenfassung: Boenigk CFI .994, TLI .989, RMSEA .067, SRMR .022;
- Working Paper: CFI .995, TLI .992, RMSEA .036, SRMR .023 bzw. später CFI .990, RMSEA .036;
- `BATCH_01_LAVAAN_SUMMARY.csv`: mehrere Boenigk-Versionen mit CFI .993–.995 und RMSEA .027–.033;
- neue `CORRECTED_FIT_INDICES.csv`: CFI 1.000, RMSEA 0.000.

Diese Werte können aus anderen Indikator-, Outcome-, Missing- oder Stichprobenspezifikationen stammen. Ohne eindeutige Modell-ID, Formel, N und Datenhash sind sie nicht austauschbar.

### 5.3 „Perfekter“ Fit ist kein Gütesiegel ohne Freiheitsgrade

Die neue Executive Summary interpretiert CFI = 1 und RMSEA = 0 als „perfect or near-perfect fit“. Die CSV speichert aber weder χ², df, SRMR, N noch Warnungen. Ein gerade oder nahezu identifiziertes Modell kann trivial perfekten Fit zeigen und prüft die Theorie nur schwach. Die neue CFA/SEM braucht daher:

- df und χ²;
- robuste Fitindizes und RMSEA-CI;
- standardisierte Ladungen mit Unsicherheit;
- Residuen/Modification Indices;
- Faktorvarianzen und Korrelationen;
- Prüfung auf Zwei-Indikator-/Single-Indicator-Probleme;
- dokumentierte N und Missing-Strategie.

### 5.4 Invarianztest: nicht bestanden, sondern fehlgeschlagen

`INVARIANCE_RESULTS_ROBUST.csv` enthält:

- Single-group baseline: `NA`, Fehler „Can't combine ... double and lavaan.vector“;
- Configural: `NA`, nur der Hinweis „Alternative LR test by group instead“.

Es existieren weder configural, metrisch noch skalar geschätzte Modelle. Dennoch melden README und Master-Narration „full invariance“ bzw. ΔCFI < .01. Das ist Evidenzklasse D.

Zusätzlich ist die Gruppierungsvariable `RC_Awareness` im Repo nicht hergeleitet. Wenn sie aus TOM/SAW entsteht oder eng damit gekoppelt ist, ist eine Gruppierung nach Awareness bei gleichzeitiger Messung von Recognition mit TOM/SAW zirkulär bzw. range-restricted. Bei ordinalen Items sind für skalare/strenge Invarianz Schwellenrestriktionen sorgfältig zu spezifizieren; bloße `intercepts` reichen nicht als dokumentierte Strategie.

**Entscheidung:** Keine Invarianzaussage in die Dissertation übernehmen.

---

## 6. Outcome- und Strukturmodellaudit

### 6.1 Codebuchgesicherte Outcome-Bedeutungen

Das hochgeladene Codebuch definiert:

- `OF01`: Anzahl ausgewählter Rollen/Statusoptionen oder negative Ausweichoption; **keine Spendenintention**;
- `OF02_01`: Höhe der letzten Spende;
- `OF02_02`: im vergangenen Jahr an diese Organisation gespendeter Gesamtbetrag;
- `OF02_03`: geplanter Betrag der kommenden zwölf Monate.

Der Quotient `OF02_02 / OF02_01` ist keine beobachtete Frequenz. Die neue Pipeline verwirft diesen Quotienten richtigerweise im Hauptmodell.

### 6.2 Neue Hurdle-Logik: grundsätzlich sinnvoll, aber nicht vollständig validiert

Die neue Pipeline setzt:

```r
donated = as.numeric(OF02_02_num > 0)
donation_amount = if_else(OF02_02_num > 0, OF02_02_num, NA_real_)
```

und modelliert:

- Spendenentscheidung: Bernoulli/logit;
- positiver Betrag: Gamma/log.

Das ist konzeptionell besser als ein einziges lineares Modell. Es bleiben aber zentrale Fragen:

- Wie wurden Freitextangaben wie `100€`, `100€ jährlich`, `30 euro` bereinigt?
- Was bedeutet fehlend gegenüber echtem Nullbetrag?
- Wurden Ausreißer, Währung, Intervalle und Mehrfachangaben behandelt?
- Warum werden N = 746, 1.336 und 656 in verschiedenen Berichten genannt?
- Wurde die zweistufige Selektion im Betragsmodell berücksichtigt?

Ohne Transformationsprotokoll und vollständige Deskriptivstatistik ist die Outcome-Validität nur teilweise belegt.

### 6.3 Neue Hauptkoeffizienten nicht verifizierbar

Die Executive Summary berichtet für die binäre Spendenentscheidung RC = .362, TR = .277 und CO = 1.045 sowie für den Betrag RC = .159, TR = −.103 und CO = .345. Diese Zahlen stehen in keiner neuen Ergebnis-CSV. Gespeichert sind weder:

- Koeffizienten- und Kovarianzmatrizen;
- Standardfehler/CIs je Modell;
- Modell-N und Events;
- Random-Effect-Schätzungen;
- Konvergenzwarnungen;
- Residual-/Influence-Diagnostik.

Damit sind die berichteten Effekte Evidenzklasse C und noch nicht dissertationsfähig.

### 6.4 „Sequential pathway confirmed“ ist überzogen

Das neue SEM endet bei Commitment. Die Spendenoutcomes werden anschließend in separaten manifesten GLMMs modelliert. Daher testet die Pipeline **kein einheitliches latentes SEM `RC → TR → CO → Donation`**, obwohl der Bericht dies behauptet.

Außerdem sind die Daten cross-sectional. Selbst bei korrekter Mediation kann zeitliche und kausale Sequenz nicht identifiziert werden. Zulässig wäre:

> Die beobachteten Querschnittsassoziationen sind mit einem theoretisch postulierten sequenziellen Muster von Recognition über Trust und Commitment vereinbar.

Nicht zulässig ist:

> Recognition increases trust, which drives commitment, which drives donations.

---

## 7. Vollständige CSV-/Ergebnisdateiaudit

### 7.1 Neue Dateien aus `COMPREHENSIVE_RESULTS`

| Datei | Tatsächlicher Inhalt | Problem | Evidenzklasse |
|---|---|---|---:|
| `BAYES_GLM_DIAGNOSTICS.csv` | 5 Modelle; Samples, max R-hat, min `neff_ratio` | Spalte heißt fälschlich `ESS_min`, ist aber ein Verhältnis; keine Parameter, PPC, LOO, MCSE, Bulk-/Tail-ESS, Divergenzen, Treedepth, BFMI | C |
| `BAYES_SEM_COMPARISON.csv` | 5 Modellnamen, je 16.000 Samples, 4 Chains, „Complete“ | Kein Modellvergleich, keine Parameter, keine Diagnostics oder Fitmaße | D |
| `MODERATION_SUMMARY.csv` | 8 Tests, alle `TRUE` | Code setzt `TRUE`, wenn Modellaufruf nicht abbricht; kein Signifikanztest | D |
| `INVARIANCE_RESULTS_ROBUST.csv` | 2 fehlgeschlagene Versuche | Belegt Scheitern, nicht Invarianz | D für positive Claims; A als Fehlerprotokoll |
| `HETEROGENEOUS_EFFECTS_ROBUST.csv` | 3 Random-Slope-Varianzen | Keine Unsicherheit, Singularity-/Konvergenzprüfung oder Modellvergleiche | C |
| `SENSITIVITY_ANALYSIS_ROBUST.csv` | 3 Gruppen mit N, Donors, RC-/CO-Koeffizienten | „Org size“ ist Zahl der Surveyzeilen je Org; `ntile` wird auf Personenzeilen angewandt; keine CIs/p-Werte/Clusterkorrektur | D für Robustheitsclaim |

### 7.2 `CORRECTED_FIT_INDICES.csv`

Diese Datei enthält fünf Statuszeilen. Für die ersten beiden Modelle stehen nur CFI = 1 und RMSEA = 0; für „Clustered SEM“ steht Text statt Fitwerten. Tatsächlich schätzt Phase 5 manifeste `lmer/glmer`-Modelle, kein „WLSMV + Cluster“-SEM. Die Zeilen „Valid“, „Adjusted“ und „Converged“ sind keine ausreichende Diagnostik.

### 7.3 Alte `BATCH_OUTPUTS`

#### `BATCH_01_LAVAAN_SUMMARY.csv`

Enthält vier Modellfitzeilen. Sie sind als Modellinventar nützlich, aber N, df, Schätzer, Missing-Strategie, Outcome-Sets und Konvergenz fehlen. AIC/BIC dürfen zwischen Modellen mit unterschiedlichen Outcomes oder Fallmengen nicht als einfacher Modellvergleich interpretiert werden.

#### `BATCH_02_GLM_COMPARISON.csv`

Beide AIC-Werte sind `NA`. Jeder Bericht, der aus dieser Datei einen AIC-Vorteil ableitet, ist unbelegt.

#### `BATCH_02_GLM_PATHS.csv`

Berichtet fünf Koeffizienten eines alten Modells für `OF02_Freq`. Signifikant sind RC (p=.0446), CO (p<.001) und ein numerisch linear behandeltes `org` (p=.0338). Das Outcome ist ungültig, `org` ist keine sinnvolle lineare Kovariate und Clustering wird nicht korrekt modelliert. Nicht integrieren.

#### `BATCH_03_BAYESIAN_DRAWS_M1/M2.csv`

Das sind die einzigen vollständigen Draw-Dateien im Repo: jeweils 16.000 Ziehungen. Sie gehören zu den **alten Gamma-Modellen für `OF02_Freq`**, nicht zu den neuen fünf Bayesian GLMs.

Aus den Draws direkt nachgerechnet:

| Modell/Parameter | Posterior Mean | 95%-Intervall | P(β>0) | Interpretation |
|---|---:|---:|---:|---|
| M1 `RC_Awareness` | .090 | [−.003, .181] | .972 | Intervall enthält 0; kein robuster Haupteffekt |
| M2 Recognition | .041 | [−.148, .230] | .665 | unbestimmt |
| M2 Familiarity | −.059 | [−.169, .052] | .145 | unbestimmt |
| M2 Trust | .043 | [−.087, .168] | .750 | unbestimmt |
| M2 Commitment | .296 | [.164, .428] | >.999 | positiver Zusammenhang, aber für ungültiges Quotienten-Outcome |

Dieser in den neuen Berichten fehlende Befund ist wichtig: Die älteren Bayes-Auswertungen stützen nicht pauschal alle Komponenten, sondern im Vollmodell nur Commitment eindeutig – und das für ein Outcome, das die Audit selbst verworfen hat.

#### `BATCH_04_ORG_INDICATORS.csv`

Enthält 25 statt 26 Organisationen und insgesamt 1.337 Bewertungen. Die Cluster sind extrem ungleich:

- min = 2, Median = 17, max = 413;
- 15 von 25 Organisationen haben N < 30;
- 12 von 25 haben N < 15;
- größte Organisation = 30,9 % aller Bewertungen;
- fünf größte Organisationen = 65,7 % aller Bewertungen;
- Organisation 11 hat keine auswertbare Betrags-/„Frequenz“-Angabe.

Dies fehlt in Executive Summary und Working Paper als quantitative Einschränkung. Es ist zentral für Random Slopes, Organisationsvergleiche und externe Validität.

#### `BATCH_05_ORG_HETEROGENEITY.csv`

Enthält nur Spannweiten über 25 Organisationen. Spannweiten sind stark von Extremgruppen mit N=2–4 abhängig und belegen keine statistische Heterogenität.

#### Bayesian-SEM-Schätztabellen

`BAYESIAN_SEM_bo_3outcome_*` und `4outcome_*` speichern nur Punktschätzungen, keine posterioren Intervalle oder Diagnostik. Sie enthalten weiterhin:

- den ungültigen latenten Faktor `INTENTION =~ OF01`;
- im 4-Outcome-Modell den ungültigen Quotienten `OF02_Freq`;
- sehr kleine standardisierte direkte Outcome-Pfade für Recognition (ca. .013–.019) und Trust (ca. .033–.062);
- größere, aber weiterhin moderate Werte für Commitment (ca. .020–.102) und das falsch bezeichnete `INTENTION`-Konstrukt.

Diese Ergebnisse widersprechen der späteren Bereinigung und dürfen nicht als Bayesian-Validierung des neuen Hurdle-Modells verwendet werden.

### 7.4 Moderationsdateien vor dem neuen Commit

Die älteren Moderations-CSVs bilden ein heterogenes Set aus Gamma-Modellen, Stratifizierungen und Cross-Level-Konstruktionen:

- Frequentistisch ist RC × Awareness im Betragsmodell nicht signifikant (β=.0298, p=.729).
- Bayesian wird derselbe benannte Effekt positiv berichtet (Mean=.109, 95%-CI [.012,.234]).
- TR × CO ist frequentistisch und Bayesian nicht eindeutig.
- mehrere „signifikante“ Tests verwenden Spendentercile oder Organisationsmittelwerte, die aus Outcome bzw. denselben Individualdaten gebildet wurden.
- eine vermeintliche „conditional indirect effect“-Berechnung ist lediglich die Differenz zweier RC-Koeffizienten nach Umzentrierung und keine formale moderierte Mediation.
- `BAYESIAN_MODERATION_POSTERIOR_DONOR.csv` enthält nur 1.000 statt der behaupteten 16.000 Draws eines einzelnen Interaktionsparameters.

Wegen Outcome-Selektionslogik, Multiplizität, inkonsistenter Modelle und fehlender kompletter Diagnostik sind diese Resultate nicht für Hypothesenbestätigung geeignet.

---

## 8. Audit der neuen Berichte

### 8.1 `EXECUTIVE_SUMMARY.md`

#### Nachweislich falsche oder unbelegte Aussagen

| Aussage | Auditbefund |
|---|---|
| „2,038 individuals across 26 organizations“ | 2.038 sind im Code Zeilen; echte Personen-ID fehlt; Ergebnis-CSV zeigt 25 Organisationen/1.337 Bewertungen. |
| „trust and commitment drive donation behavior“ | Querschnittsdaten; nur Assoziation möglich. |
| „sequential pathway confirmed“ | Kein gemeinsames latentes Outcome-SEM; SEM endet bei Commitment. |
| „all measures perfect fit“ | df/χ²/N/Ladungen fehlen; möglicher trivialer Fit. |
| N=746, „1,336 after imputation“ | Im Code ist keine Imputation implementiert; neue Modelle filtern Complete Cases. |
| „8 tests, all converged“ und danach „significant moderations“ | Konvergenz ist nicht Signifikanz; CSV-TRUE ist hart codiert. |
| „org-size moderation“ | `org_size = n()` misst Sample-/Clustergröße, nicht reale Organisationsgröße. |
| „large organizations“ | Tercile sind auf 1.336 Zeilen annähernd gleich verteilt, nicht Organisationen nach externer Größe. |
| „commitment effect varies dramatically“ | Varianzpunkt .111 ohne CI/Test; Prozentinterpretation ist falsch. |
| „all 5 Bayesian SEM models converged, Rhat <1.001“ | SEM-CSV enthält kein R-hat; Detailed Report nennt 45–165 Divergenzen und niedrige/unbekannte ESS. |
| „no divergent transitions“ | Widerspruch zum eigenen Bayesian Report. |
| „publication-ready“ | Durch Invarianzfehler, fehlende Inputs/Outputs und falsche Moderation nicht haltbar. |

### 8.2 `BAYESIAN_DETAILED_REPORT.md`

Dieser Bericht ist intern widersprüchlich:

- Er behauptet „all Bayesian models achieved convergence“.
- Gleichzeitig nennt er 165, 45 und 78 divergente Übergänge in drei SEMs.
- Für zwei SEMs stehen Divergenzen und ESS als `?`.
- Er bezeichnet Divergenzen als „expected, not problematic“ und <5 % als akzeptabel. Stan empfiehlt dagegen idealerweise **keine** post-warmup Divergenzen; diese können den Posterior verzerren.
- Er behauptet Traceplots und stabile Mischung, speichert aber keine Traceplots oder Draws für die neuen Modelle.
- Er nennt „WLSMV estimator“ im Bayesian SEM. `bsem()` schätzt per MCMC; WLSMV ist die frequentistische DWLS/robuste Teststatistik-Logik von lavaan. Die Dokumentation muss klar zwischen ordinaler Likelihood/Latent-Response-Modellierung und WLSMV unterscheiden.
- Er dokumentiert keine expliziten Priors, obwohl Priors ein Kernteil der Bayes-Spezifikation sind.
- Er nennt fünf SEMs „competing specifications“, führt aber kein `blavCompare`, LOO/WAIC oder Posterior Predictive Model Checking durch.

Offizielle Stan-Dokumentation betrachtet Divergenzen als Validitätsproblem und empfiehlt zusätzliche Diagnostik, MCSE sowie Bulk-/Tail-ESS. Siehe [Stan diagnostics](https://mc-stan.org/learn-stan/diagnostics-warnings.html) und [RStan HMC diagnostics](https://mc-stan.org/rstan/reference/check_hmc_diagnostics.html).

### 8.3 README und ältere Berichte

Das README enthält weiterhin alte Aussagen über:

- `OF02_Freq`-Modelle;
- bestätigte Invarianz;
- 30+ Moderationstests;
- vollständig bestandene Bayesian-Diagnostik.

Damit mischt das Repo verworfene und neue Analysepfade ohne klare Deprecation. Die alten Berichte sollten in `archive/legacy_invalidated/` verschoben und mit einem Warnheader versehen werden.

### 8.4 Working Paper

Positiv:

- beschreibt Selbstbericht, Cross-Sectionalität, Reverse Causality und Convenience-Sampling;
- diskutiert Faircloth-/Romero-Messprobleme;
- trennt letzte Spende, Jahresspende und Donorstatus.

Korrekturbedarf:

- Abstract und Diskussion nennen „over 2,000 respondents“, obwohl das Erhebungsdesign wiederholte Bewertungen und die Rohdatei 503 Startfälle zeigt;
- die Generalisierbarkeit innerhalb des österreichischen NPO-Sektors wird trotz stark selektiver, donorlastiger Stichprobe zu positiv dargestellt;
- Methods stehen teils noch im Futur und beschreiben die geplante Zufallsstichprobe, die nicht realisiert wurde;
- Ergebnis-Tabellen verwenden mehrere nicht eindeutig versionierte Modelle;
- Tabelle 18 enthält predictive coefficients, für die im Repo keine exakt passende reproduzierbare Ergebnisdatei vorliegt;
- „actual donation behaviour“ sollte durchgehend „self-reported past-year donation“ heißen;
- Hypothesenbewertung muss zwischen Messmodellreplikation und Outcome-Assoziation unterscheiden.

### 8.5 Proposal und ERNOP-Papier

Das Proposal plant eine repräsentative allgemeine Zufallsstichprobe und eine Clusterzufallsstichprobe großer NPOs. Das erreichte Design ist laut Working Paper eine donorlastige clustered convenience sample mit wenigen unterstützenden Organisationen plus allgemeiner Rekrutierung. Das ist keine bloße Limitation, sondern eine Änderung des Designs und muss als solche explizit dokumentiert werden.

---

## 9. Methodische Kernprobleme

### P0.1 Analyseeinheit und Abhängigkeit

Ohne echte Personen-ID sind Standardfehler, effektive Stichprobengröße und Mehrebenenstruktur nicht vertrauenswürdig. Bei mehreren Organisationsbewertungen pro Person braucht das Modell mindestens Random Intercepts für Person und Organisation oder ein passend cross-classified Design.

### P0.2 Stichprobenselektion

Organisationen werden nur bewertet, wenn sie bekannt sind; viele Befragte stammen aus bestehenden Donormilieus. Recognition, Trust, Commitment und Donation sind dadurch gemeinsam selektiert. Aussagen über unbekannte Organisationen, Neuspender oder die allgemeine österreichische Bevölkerung sind nicht identifiziert.

### P0.3 Cross-sectional mediation

Trust und Commitment können Folgen früherer Spenden sein. Eine cross-sectionale Pfadordnung reicht nicht für Mediation oder „Drive“-Claims. Die Dissertation sollte von theoretisch gerichteten Assoziationen sprechen und alternative Richtungen testen.

### P0.4 Endogene/falsch benannte Moderatoren

- In `COMPREHENSIVE_CORRECTED_PIPELINE.R` wird `donor_type` direkt aus `donated` gebildet und anschließend `donated ~ rc_z * donor_type` modelliert. Der Moderator ist deterministisch das Outcome; das Modell ist logisch ungültig.
- `org_size = n()` ist die Zahl analysierter Surveyzeilen pro Organisation, nicht Organisationsgröße.
- Spendentercile entstehen aus dem Outcome selbst und dürfen dessen Zusammenhang nicht als exogene Moderation erklären.
- Organisationsmittelwerte aus denselben Antworten brauchen saubere Within-/Between-Zerlegung und Leave-one-out-Aggregation, sonst entstehen atomistische/ökologische und part-whole Verzerrungen.

### P0.5 Multiplizität und HARKing-Risiko

Das Repo nennt 30+ Interaktionen, speichert aber keine vollständige Testfamilie, keine Präregistrierung und keine Fehlerkontrolle. Aus vielen explorativen Tests selektierte p<.05-Effekte dürfen nicht als bestätigte Moderatoren erscheinen. Erforderlich sind:

- definierte primäre Interaktionen;
- vollständige Ergebnistabelle aller getesteten Terme;
- FDR/Holm oder hierarchisches Shrinkage;
- klare Trennung explorativ/konfirmatorisch;
- keine Ergebnisabhängige Modellspezifikation ohne Validation Sample.

### P0.6 Random Slopes bei 25 unbalancierten Clustern

Die Random-Slope-Varianzen .0120, .0024 und .1110 sind quadrierte Standardabweichungen auf unterschiedlichen Skalen. Sie sind keine Prozentanteile. Bei 25 Clustern, davon 15 mit N<30, sind Varianzkomponenten fragil. Benötigt werden:

- `isSingular()` / Hessian-/Gradientendiagnostik;
- Korrelation von Intercept und Slope;
- Profil-/Bootstrap-CI oder Bayes-Posterior;
- Vergleich mit Random-Intercept-Modell;
- Leave-one-organisation-out Sensitivität;
- keine „dramatic“ Interpretation ohne Unsicherheit.

### P0.7 Bayesian Workflow

R-hat allein beweist keine Modellgültigkeit. Für jedes Bayes-Modell fehlen mindestens:

- explizite, begründete Priors und Prior Predictive Checks;
- vollständige Draws oder gespeicherte Fitobjekte;
- Rank-normalized split R-hat;
- Bulk- und Tail-ESS, MCSE;
- Divergenzen, Treedepth, BFMI;
- posterior predictive checks;
- Sensitivität gegenüber Priors;
- LOO/WAIC nur bei gleicher Outcome-/Datenbasis;
- Parameterschätzungen mit 95%-CrI und posterioren Wahrscheinlichkeiten.

Die offiziellen blavaan-Funktionen bieten u. a. `blavCompare`, `blavFitIndices`, `ppmc` und `ppp`; diese werden nicht verwendet. Siehe [blavaan-Funktionsübersicht](https://blavaan.org/reference/index.html).

### P0.8 Ordinale und multilevel SEM-Strategie

Für ordinale Endogene schaltet lavaan bei `ordered=` auf WLSMV/DWLS mit robusten SE und Teststatistik; FIML ist dort nicht unterstützt. Siehe [lavaan categorical data](https://lavaan.ugent.be/tutorial/cat.html). Das widerspricht Berichtsformulierungen, die WLSMV und FIML pauschal gleichzeitig nennen.

Ein echtes Multilevel-SEM benötigt explizite Within-/Between-Level-Blöcke und `cluster=`; manifeste Mixed Models sind eine andere Modellklasse. Siehe [lavaan multilevel SEM](https://lavaan.ugent.be/tutorial/multilevel.html). Die aktuelle Pipeline darf ihre `lmer/glmer`-Phase nicht als „Clustered SEM WLSMV+Cluster“ etikettieren.

---

## 10. Welche neuen Erkenntnisse in die Dissertation integriert werden können

### 10.1 Jetzt integrierbar – mit vorsichtiger Formulierung

#### A. Boenigk als parsimonisch stärkstes Messmodell

Mögliche Formulierung:

> In der Discovery-Stichprobe zeigte das auf Trust und Commitment fokussierte Boenigk-Modell konsistent günstigere globale Fit- und Reliabilitätskennwerte als die umfangreicheren Faircloth- und Romero-Spezifikationen. Dieser Befund spricht für eine parsimonische relationale Operationalisierung, bedarf wegen Stichprobenselektion und wiederholter Organisationsbewertungen jedoch einer clusterrobusten Replikation.

#### B. Measurement problems in Faircloth and Romero

Integrierbar sind:

- niedrige AVE/Instabilität einzelner Faircloth-Konstrukte;
- hohe latente Überlappung und Misfit im Romero-Modell;
- Notwendigkeit, Übersetzungs-/Reverse-Coding- und Inhaltsvalidität systematisch zu prüfen.

#### C. Commitment als aussichtsreichster Outcome-Prädiktor – explorativ

Mehrere heterogene Modelle deuten auf Commitment als stärksten positiven Prädiktor hin. Wegen unterschiedlicher Outcomes und fehlender vollständiger Reproduktion darf dies nur als triangulierter **explorativer** Befund formuliert werden:

> Across several exploratory specifications, commitment showed the most consistent positive association with self-reported giving measures, whereas recognition, familiarity and trust were less stable.

#### D. Unbalancierte Organisationsstruktur als Designbefund

Die Verteilung 2–413 Bewertungen pro Organisation und die Dominanz weniger Organisationen ist wichtig. Sie erklärt, warum gepoolte Ergebnisse eher die größten Samples als den österreichischen NPO-Sektor repräsentieren.

### 10.2 Erst nach Neuanalyse integrierbar

- binäre und positive Betragsmodelle;
- indirekte Effekte RC→TR→CO;
- organisationsbezogene ICCs;
- Bayesian GLM/SEM;
- Random Slopes;
- Awareness- oder echte Organisationsgrößenmoderation;
- Organisationsvergleiche.

### 10.3 Nicht integrieren

- `OF01` als Intention;
- `OF02_Freq` als Frequenz;
- donor type aus dem Outcome im binären Modell;
- Spendentercile als Moderator derselben Spende;
- volle Messinvarianz;
- alle TRUE-Werte aus der neuen Moderations-CSV;
- „large organization“ auf Basis von Surveyfallzahl;
- „160.000 samples confirm consistency“ ohne Modellparameter;
- kausale oder interventionsbezogene Praxisempfehlungen aus diesen Querschnittsdaten.

---

## 11. Empfohlene Hauptanalyse für Dissertationsniveau

### 11.1 Datenaufbau

1. Rohmodule deterministisch verknüpfen und echte Personen-ID erzeugen.
2. Jede Organisationsbewertung als eigene `evaluation_id` abbilden.
3. Flowchart von eingeladen → gestartet → verknüpft → vollständig → modellbezogenes N.
4. Missing Codes und Geldtexte mit testbaren Regeln bereinigen.
5. Roh-, Clean- und Analysis-Dataset strikt trennen; alle Transformationen versionieren.

### 11.2 Messmodell

1. A-priori Kernmodell Trust/Commitment definieren.
2. Ordinale CFA mit angemessener Clusterkorrektur oder Bayesian multilevel latent model.
3. Faktorladungen, Schwellen, Residuen, CR/ω, AVE, HTMT und Unsicherheit berichten.
4. Messinvarianz nur über exogene, sinnvoll definierte Gruppen; bei kleinen Gruppen Alignment/partial invariance nur theoriegeleitet.
5. Alternative Modelle auf Holdout/Bootstrap oder mit informationskriteriumsbasierter, fairer Datenbasis prüfen.

### 11.3 Outcomes

Primär:

- **Part 1:** irgendeine Jahresspende an die bewertete Organisation (logit/probit);
- **Part 2:** positiver Jahresbetrag (Gamma/log oder lognormal; Modellvergleich via PPC/CV);
- beide Teile mit Person- und Organisationsstruktur.

Sekundär:

- letzte Spende;
- geplante Spende, klar als Intention/Plan und nicht Verhalten;
- tatsächliche Frequenz nur, wenn separat erhoben oder validiert.

### 11.4 Inferenz

- Effektgrößen mit 95%-CI/CrI und vorhergesagten Wahrscheinlichkeiten/Beträgen;
- keine Kausalität;
- bekannte Confounder und Sample Source berücksichtigen;
- gewichtete und ungewichtete Sensitivität;
- Cluster leave-one-out;
- Missing-Data-Sensitivität;
- Präregistrierung einer reduzierten Hypothesenfamilie;
- explorative Ergebnisse separat.

---

## 12. Priorisierter Reparaturplan

### P0 – vor jeder Ergebnisübernahme

1. **Personen-/Modulcrosswalk herstellen.**
2. **RDS-Erzeugung vollständig ins Repo aufnehmen.**
3. **Missing- und Geldrecode validieren.**
4. **Alle D-Claims aus README und Reports entfernen oder als ungültig markieren.**
5. **Moderationsphase neu schreiben; Signifikanz aus Koeffizient + Unsicherheit berechnen.**
6. **Invarianz als fehlgeschlagen berichten.**
7. **`org_size` in `survey_cluster_n` umbenennen; echte Organisationsgröße extern ergänzen.**
8. **Neue Outcome- und Bayes-Modelle vollständig exportieren.**

### P1 – vor Paper-/Dissertationskapitel

9. Analyseplan mit primären/sekundären Modellen festlegen.
10. Person- und Organisationsclustering korrekt modellieren.
11. Modellversionen, N und Fitwerte harmonisieren.
12. Bayesian Prior/PPC/Diagnostics/LOO ergänzen.
13. Random Slopes nur mit Unsicherheit und Cluster-Sensitivität berichten.
14. Working Paper auf tatsächlich realisierte Stichprobe umschreiben.

### P2 – Qualitätssteigerung

15. Reproduzierbare Umgebung (`renv.lock`, R-Version, Paketversionen, Sessioninfo).
16. Relative Pfade (`here`, Projektroot), keine `/home/gerald/...`-Pfade.
17. Tests für Recode, IDs, Range, Duplikate und Outcome-Logik.
18. Quarto/R Markdown als single source of truth; Berichte direkt aus Modellobjekten rendern.
19. Legacy-Outputs archivieren und mit Gültigkeitsstatus versehen.
20. Release mit DOI/Zenodo, Data Dictionary und reproduzierbarer Audit-Trail.

---

## 13. Mindestanforderungen an jede Ergebniszeile

Jeder berichtete Befund sollte automatisch enthalten:

- eindeutige `analysis_id` und Git-Commit;
- Datenhash und Filterdefinition;
- Einheit der Analyse;
- N Personen, N Bewertungen, N Organisationen, Events/Donors;
- Formel, Familie/Link, Schätzer;
- Missing-Strategie;
- Effekt, SE oder Posterior-SD, 95%-Intervall;
- p-Wert oder vorab definierte Bayes-Entscheidungsgröße;
- Modellfit und relevante Diagnostik;
- Multiplicity-Familie;
- Status: primary / secondary / exploratory / invalidated.

Ohne diese Felder sollte ein Wert nicht automatisch in einen narrativen Bericht übernommen werden.

---

## 14. Reproduzierbarkeits- und Claim-Register

| Claim | Datei/Ort | Evidenz | Status | Maßnahme |
|---|---|---|---|---|
| 2.038 Personen | Executive Summary / Master text | Zeilen-ID statt Person-ID | **invalidiert** | echte Personenzahl rekonstruieren |
| 26 Organisationen | Executive Summary | Org-CSV enthält 25; Modell-N unklar | **unaufgelöst** | Flowtable je Modell |
| CFA/SEM perfekter Fit | Corrected fit CSV | nur CFI/RMSEA; keine df | **nicht interpretierbar** | vollständigen Output exportieren |
| RC→TR→CO | SEM-Code | strukturelle Pfade vorhanden | **explorativ** | clusterrobust + Unsicherheit |
| →Donation im selben Pfad | Bericht | nicht im SEM geschätzt | **falsch dargestellt** | getrennte Modelle korrekt benennen |
| Commitment OR=2.84 | Executive Summary | kein passender Ergebnisexport | **nicht verifiziert** | `broom.mixed`/posterior exportieren |
| 15.9 % Donation-ICC | Bericht | kein passender neuer Output | **nicht verifiziert** | binomial ICC/latent scale dokumentieren |
| 8 signifikante Moderationen | Moderation CSV + Code | TRUE = Modell lief | **invalidiert** | komplette Interaktionstabelle neu rechnen |
| Größenmoderation | Sensitivity CSV | Cluster-N, nicht Org-Größe | **invalidiert** | externe Orggröße verwenden |
| volle Invarianz | README/Master | Invariance CSV = Fehler | **invalidiert** | nicht berichten |
| Random slopes heterogen | Heterogeneity CSV | nur Varianzpunkt | **unbestimmt** | CI/Test/Singularity/LOO |
| 5 Bayes SEM verglichen | Comparison CSV | kein Vergleich | **invalidiert** | Parameter + PPC + Vergleich |
| alle Bayes SEM konvergiert | Detailed Report | Divergenzen und fehlende Diagnostics | **invalidiert** | neu fitten/diagnostizieren |
| 5 Bayes GLM konvergiert | Diagnostics CSV | R-hat plausibel; Diagnostik unvollständig | **teilweise** | vollständige Fits/Draws/PPC |
| robuste Resultate | Executive Summary | Koeffizienten stark unterschiedlich; kein formaler Test | **invalidiert** | vorab definierte Robustheitskriterien |
| Boenigk psychometrisch überlegen | Skalenberichte + Batch fit | mehrere Quellen konsistent | **vorläufig gestützt** | Modellversionen harmonisieren |
| Commitment stabilster Prädiktor | diverse alte/neue Berichte | Richtung konsistent, Outcomes/Modelle heterogen | **explorativ** | korrekte Hurdle-Neuanalyse |

---

## 15. Dateien und Integritätsnachweise

Ausgewählte SHA-256-Prüfsummen:

- Roh-CSV: `c9f397ad944eac82a812027c394fc19f057522b4a4630d54950dfdd154db98ef`
- Codebuch-XLSX: `6c543ddc4acb3a45a448eb3548b87a9f6df3b8b40e5c445e2e2d28b7cfc718d0`
- Working Paper DOCX: `f2a4461fcc64dfc5e6012dbf95d3f636d5dd67e58d9d991d45186da3fb2439c4`
- neue Executive Summary: `03f08a0fe74254caa83db399feea585ca47efe55ef13165142b0a55660f33514`
- neue Bayes-Diagnose-CSV: `299c7c953a8bcb97f1da8567c13788116d065c7c9c2bf700bc21fffcca0570bc`
- neue Invarianz-CSV: `d3d826d8bc7a02786c42608958e0fd962d3c1e143c7bec024737eccf6274bdde`

---

## 16. Schlussfolgerung

Der neue Repo-Stand zeigt eine richtige strategische Richtung: ordinale Messmodelle, getrennte Spendenentscheidung und Spendenhöhe sowie Mehrebenenmodelle. Die Ausführung und Berichterstattung erreicht das erforderliche Dissertationsniveau aber noch nicht.

Die wichtigste inhaltliche Botschaft ist gegenwärtig enger als die Executive Summary behauptet:

> Die Discovery-Daten sprechen dafür, Trust und insbesondere Commitment als parsimonische relationale Kernkomponenten von Nonprofit Brand Equity weiterzuverfolgen. Die Stärke ihres Zusammenhangs mit selbstberichteten Spenden sowie organisationsabhängige Moderationen sind wegen ungeklärter Personenstruktur, selektiver Stichprobe und unvollständiger Ergebnisprovenienz noch offen.

Das ist wissenschaftlich defensiver, aber auch aussagekräftiger: Es trennt einen gut begründeten Messbefund von noch nicht belastbarer Outcome-, Moderations- und Kausalinferenz.

