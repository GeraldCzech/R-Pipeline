Methodisches Audit des Repositories „R-Pipeline“

Stand: 23. August 2026
Geprüfter Commit: ae88d939a5188e1265b00a2f65cfc9e6cb83df17
Bezugsrahmen: Dissertationsniveau, Anschlussfähigkeit an die aktuelle BEBA-Architektur und Vergleich mit Proposal, ERNOP-Papier, Working Paper, Skalenanalysen, Codebook und Rohdatenexport.

Kurzurteil

Das Repository enthält wertvolle explorative Hinweise, ist in seinem gegenwärtigen Zustand aber weder als reproduzierbares Forschungsprojekt noch als belastbare Ergebnisgrundlage für zentrale Dissertationsaussagen ausreichend. Besonders tragfähig ist die erneute Evidenz für den relationalen Kern aus Trust und Commitment sowie der Befund, dass reine Familiarity/Awareness-Konstrukte deutlich schwächer und instabiler sind. Die neueren Moderations-, Multilevel- und Bayesian-Erzählungen sind dagegen nur teilweise durch den vorhandenen Code gedeckt; mehrere starke Aussagen sind methodisch falsch interpretiert oder im Repository nicht verifizierbar.

Die richtige Verwendung ist daher:

1. 2025 als Discovery- und Modellvergleichsphase behandeln;
2. nur robuste Messbefunde und klar als deskriptiv gekennzeichnete Muster in die Dissertation übernehmen;
3. Moderation, Multilevel-Struktur, Mediation und Outcome-Modellierung mit der 2026er Studie präregistriert neu testen;
4. die gegenwärtigen Effekt- und Kausalaussagen nicht unverändert übernehmen.

Gesamtbewertung

Die Punktwerte sind heuristische Auditurteile, keine formale Qualitätsmetrik.

|Dimension                      |Urteil|Begründung                                                                                                                                           |
|-------------------------------|-----:|-----------------------------------------------------------------------------------------------------------------------------------------------------|
|Theoretische Anschlussfähigkeit|7/10  |Trust, Commitment, Intention und Behaviour passen gut zur BEBA-Logik; die Reihenfolge und Benennung der Konstrukte ist aber nicht überall konsistent.|
|Messmodell-Evidenz             |7/10  |Boenigk-Trust/Commitment ist über mehrere Vorarbeiten stabil; Faircloth und Romero zeigen bekannte Fit- und Diskriminanzprobleme.                    |
|Strukturelle Aussagekraft      |3/10  |Cross-sectional, common-source, teilweise falsch benannte Variablen und nicht verifizierbare Pfadbehauptungen.                                       |
|Moderation/Multilevel          |2/10  |Kein tatsächlich geschätztes Multilevel-SEM, kleine und stark ungleiche Cluster, endogene Gruppenaggregate und fehlende Testlogik.                   |
|Bayesianische Evidenz          |3/10  |Einzelne Posterior-Signale sind interessant; Priors, posterior predictive checks, Diagnostik und vollständige Modellobjekte fehlen.                  |
|Reproduzierbarkeit             |2/10  |Zentrale Daten, Hauptskripte, Modellobjekte, Umgebungs-Lockfile und Tests fehlen; absolute lokale Pfade verhindern ein unabhängiges Re-Run.          |
|Berichtskonsistenz             |2/10  |Mehrere N-, Organisations-, Fit- und Effektangaben widersprechen einander oder den mitgelieferten Tabellen.                                          |

Dissertationsurteil: gutes exploratives Laborbuch und Ergebnis-Snapshot; noch keine publikations- oder dissertationsfertige Evidenzbasis.

Was tatsächlich robust erscheint

1. Trust und Commitment sind der stärkste empirische Kern

Die frühere Skalenanalyse und die bereitgestellten Manuskripte ergeben ein konsistentes Bild:

• Boenigk Trust: Cronbachs α ungefähr .915;
• Boenigk Commitment: Cronbachs α ungefähr .943;
• sehr saubere Zwei-Faktoren-Struktur in der EFA;
• CFA im früheren Bericht: CFI .994, TLI .989, RMSEA .067, SRMR .022;
• Omega und AVE liegen in den bereitgestellten Zusammenfassungen jeweils auf hohem Niveau.

Das ist der am besten abgesicherte Teil des gesamten 2025er Materials. Er unterstützt die Entscheidung, Trust und Commitment als relationale Mechanismen beziehungsweise als Brückenkonstrukte zwischen Branding und Verhalten in der Dissertation beizubehalten.

2. Familiarity/Awareness ist kein stabiler Ersatz für Markenwirkung

Die älteren Analysen zeigten bereits schwächere beziehungsweise komplexere Strukturen bei Familiarity/Awareness. Das Repository bestätigt eher diese Zurückhaltung als eine starke Awareness-Theorie. Daraus folgt kein Nachweis, dass Awareness irrelevant ist; wohl aber, dass sie nicht als hinreichender Wirkmechanismus behandelt werden sollte.

Für BEBA ist das inhaltlich nützlich: Awareness kann als Reichweiten-, Expositions- oder Segmentierungsmerkmal modelliert werden, während die eigentliche psychologische Transmission über Glaubwürdigkeit/Recognition, Trust, Commitment beziehungsweise Motivation und Intention läuft.

3. Organisationsheterogenität ist eine plausible Forschungsfrage

Die Outputs zeigen erkennbare Unterschiede zwischen Organisationen. Das rechtfertigt eine theoretische Frage nach Kontextabhängigkeit und partieller Pooling-Logik. Es rechtfertigt noch keine präzisen Behauptungen über die Größe von Random Slopes oder organisationale „Unterdrückungseffekte“. Die Heterogenität ist derzeit ein Motiv für bessere Modelle, kein bereits etablierter Mechanismus.

4. Donor-Status beziehungsweise Regelmäßigkeit könnte ein echter Boundary Condition sein

Der frequentistische Code vergleicht lediglich separat geschätzte Stratum-Koeffizienten; daraus folgt kein formaler Moderationstest. Im Bayesian-Output liegt für die Donor-Interaktion jedoch ein interessantes Signal vor. Da beide Analysestränge nicht konsistent ausgewertet und dokumentiert sind, ist dies hypothesengenerierend, aber für eine konfirmatorische Dissertation sehr gut anschlussfähig.

Zentrale methodische Befunde des Audits

A. Das Repository ist nicht reproduzierbar

Die vier Analyseskripte verwenden einen fest codierten Pfad (/home/gerald/R-pipeline) und erwarten eine Datei pipeline_data_fc_bo_with_ordinal_awareness.rds, die nicht im Repository enthalten ist. Ebenfalls fehlen:

• die Hauptpipeline, mit der SEM-, Invarianz- und Batch-Ergebnisse erzeugt wurden;
• die vollständigen Datenaufbereitungsregeln;
• gespeicherte SEM-Modellobjekte und vollständige Posterior Draws;
• renv.lock oder ein vergleichbarer Umgebungsnachweis;
• sessionInfo(), automatisierte Tests, Logs und eine maschinenlesbare Pipeline-Konfiguration.

Damit lassen sich die publizierten Tabellen nicht unabhängig vom Rohmaterial bis zum Ergebnis rekonstruieren. Ein Werkzeug wie targets wäre geeignet, um Abhängigkeiten, Seeds und Wiederholbarkeit sichtbar zu machen.

B. Das als Multilevel-SEM bezeichnete Skript schätzt kein Multilevel-SEM

MODERATION_MULTILEVEL_SEM.R definiert zwar eine lavaan-Modellspezifikation, fitten lässt der Code diese Spezifikation aber nicht. Tatsächlich werden lme4::lmer-Modelle auf manifesten Zeilenmittelwerten geschätzt. Der Ergebnisbereich darf daher nicht als „Multilevel SEM“ bezeichnet werden.

Zusätzlich zeigen die Outputs nur 25 Organisationen, während der README-Text 26 nennt. Die Cluster sind stark ungleich verteilt: ungefähr 2 bis 413 Beobachtungen, Median etwa 17; sieben Organisationen haben weniger als zehn und dreizehn weniger als zwanzig Beobachtungen. Random-Slope-Schätzungen sind bei nur 25 Clustern und sehr kleinen Zellen fragil; Small-Sample-Korrekturen und Sensitivitätsanalysen sind hier zentral (McNeish & Stapleton, 2016).

Besonders wichtig: Die zugrunde liegende Befragungslogik erlaubt mehrere Organisationsbewertungen pro Person. Ein reines Organisationsmodell berücksichtigt diese Abhängigkeit nicht. Die Analyseeinheit muss als Person–Organisation-Evaluation definiert und gegebenenfalls kreuzklassifiziert modelliert werden: Random Intercepts beziehungsweise Clusterkorrekturen für Person und Organisation.

C. „1.681-fache Variation“ ist eine Fehlinterpretation

Das Modell OF02_02_num ~ CO + TR + RC + (CO | org) berichtet für den Commitment-Slope eine Varianz von etwa 1681. Diese Zahl liegt auf der quadrierten Skala des monetären Outcomes. Sie bedeutet nicht, dass der Effekt sich zwischen Organisationen „1.681-fach“ unterscheidet.

Die Zahl ist zudem stark von der Euro-Skalierung und der schiefen Spendenverteilung abhängig. Falls der Random Slope weiter untersucht wird, sollten berichtet werden:

• Random-Slope-Standardabweichung in interpretierbarer Skalierung;
• Korrelation von Random Intercept und Random Slope;
• Singularitäts- und Einflussdiagnostik;
• organisationsspezifische Posterior-/Shrinkage-Intervalle;
• Sensitivität gegenüber Lognormal-, Gamma- und Hurdle-Modellen.

D. Mehrere Moderatorvariablen sind endogen oder tautologisch

Im Code wird der organisationsbezogene Spendenmittelwert aus genau demselben individuellen Outcome gebildet, das anschließend erklärt werden soll. Jede Person trägt damit zu ihrem eigenen „Kontext“-Prädiktor bei. Ohne Leave-one-out-Aggregation oder externe Organisationskennzahl entsteht Leakage und Endogenität.

Noch problematischer ist die Einteilung des jährlichen Spendenbetrags in Tertile, die danach als Moderator für denselben Spendenbetrag verwendet werden. Dies ist keine unabhängige Moderation, sondern eine outcome-definierte Stratifizierung. Die resultierenden Unterschiede dürfen nicht als Wirkungsheterogenität interpretiert werden. Auch die generelle Kategorisierung kontinuierlicher Variablen verliert Information und kann Artefakte erzeugen (Altman & Royston, 2006).

E. Die behauptete „conditional indirect effect“-Analyse ist keine Mediation

Das entsprechende Skript schätzt keine Mediatorgleichung und kein Produkt aus a- und b-Pfad. Stattdessen wird ein Awareness-Wert verschoben und die Änderung eines reparametrisierten Regressionskoeffizienten als indirekter Effekt bezeichnet. Diese Berechnung ist weder eine einfache noch eine moderierte Mediation.

Für die Dissertation sollte die Mediation ausschließlich über explizite Strukturpfade, indirekte Effekte und Unsicherheitsintervalle definiert werden. Bei cross-sectional Daten ist von indirekten Assoziationen, nicht von zeitlicher oder kausaler Mediation zu sprechen.

F. Donor-Type-„8,9×“ ist kein gültiger Moderationsnachweis

Die Zahl entsteht aus dem Verhältnis zweier separat geschätzter Koeffizienten (ungefähr .204/.023). Ein Verhältnis zweier Stratum-Koeffizienten ist kein Interaktionstest, besitzt hier kein ausgewiesenes Unsicherheitsintervall und ist besonders instabil, wenn der Nenner nahe null liegt.

Korrekt wäre ein gemeinsames Modell mit Interaktion, marginalen Effekten auf der Antwortskala und einem Intervall für die Differenz der Slopes. Das Bayesian-Skript enthält zwar eine solche Interaktion und berichtet ein von null getrenntes Credible Interval; aufgrund der unvollständigen Modell- und Prior-Dokumentation sollte dies als Replikationskandidat, nicht als fertiges Dissertationsergebnis gelten.

G. Organisationsmittelwerte werden in Einzelebenen-GLMs pseudo-repliziert

Mehrere „Cross-Level“-Analysen wiederholen einen Organisationsmittelwert in allen individuellen Zeilen und fitten anschließend ein einfaches Gamma-GLM ohne Organisationsclusterung. Dadurch wird die effektive Information auf Organisationsebene überschätzt und die Unsicherheit tendenziell zu klein ausgewiesen.

Erforderlich sind eine echte Within-/Between-Zerlegung und ein Modell, das die Clusterstruktur berücksichtigt. Bei internen Aggregaten sollte zusätzlich eine Leave-one-out- oder Split-Sample-Variante eingesetzt werden; besser sind externe, theoretisch begründete Organisationsmerkmale.

H. Das Outcome OF02_Freq ist keine Spendenfrequenz

Laut Codebook ist:

• OF02_01 der Betrag der letzten Spende;
• OF02_02 der gesamte Spendenbetrag im vergangenen Jahr;
• OF02_03 der geplante Betrag für die nächsten zwölf Monate.

Der Quotient OF02_02 / OF02_01 gibt höchstens „Äquivalente der letzten Spendenhöhe“ wieder. Er entspricht nur dann einer Frequenz, wenn alle Einzelspenden gleich hoch wären. Nullwerte und extreme Quotienten verschärfen die Messfehler. Dieses Outcome sollte umbenannt oder verworfen werden. Eine tatsächliche Frequenz muss direkt erhoben werden.

I. Das Bayesian-SEM benennt OF01 fälschlich als Intention

Im Repository wird INTENTION =~ OF01 spezifiziert. Das Codebook beschreibt OF01 jedoch als Anzahl beziehungsweise Zusammenfassung angekreuzter Rollen wie Spender:in, Mitglied oder Unterstützer:in. Nur OF01_07 bildet eine dichotome zukünftige Spendenabsicht ab. Damit ist der zentrale Pfad „Commitment → Intention → Donation“ in diesem Modell konstruktseitig nicht valide.

Für die 2026er Studie sind die geplanten mehrindikatorischen Intention-Items (TI04_01 bis TI04_03) der methodisch richtige Anschluss. OF01 darf nicht als latente Intention bezeichnet werden.

J. Die prominent berichteten Pfade sind im Repository nicht belegt

Der README-Text nennt .847, .602 und .395 für Recognition → Trust, Trust → Commitment und Commitment → Donation. Die enthaltene Bayesian-SEM-Tabelle weist dagegen unter anderem folgende standardisierte Punktschätzungen aus:

|Pfad                                     |Standardisierte Punktschätzung im enthaltenen Output|
|-----------------------------------------|---------------------------------------------------:|
|Recognition → Trust                      |.246                                                |
|Brand Fit → Trust                        |.248                                                |
|Trust → Commitment                       |.447                                                |
|Recognition → Commitment                 |.164                                                |
|Brand Fit → Commitment                   |.372                                                |
|Commitment → angebliche „Intention“      |.265                                                |
|angebliche „Intention“ → jährliche Spende|.139                                                |
|Commitment → jährliche Spende            |.101                                                |

Die Zahlen .847/.602/.395 erscheinen in narrativen Dokumenten, aber nicht in einem nachvollziehbaren Ergebnisobjekt des Repositories. Sie sollten nicht zitiert werden, bevor Modell, Datenversion, Schätzung und Intervall eindeutig rekonstruiert sind. Selbst die enthaltenen Punktschätzungen sind ohne vollständige Posteriorintervalle und Diagnostik nur deskriptiv.

K. Bayesianische Konvergenz ist unvollständig dokumentiert

Für die Moderationsmodelle werden R-hat-Werte berichtet; für das Bayesian-SEM fehlen im Repository jedoch die angekündigten vollständigen Draws und Fit-Objekte. Die als „ESTIMATES“ bezeichnete Datei enthält Parameterzeilen, keine 16.000 Posteriorziehungen. Ebenfalls fehlen beziehungsweise sind nicht nachvollziehbar:

• begründete informative oder schwach informative Priors;
• Prior-Predictive Checks;
• Posterior-Predictive Checks;
• bulk und tail ESS;
• MCSE;
• Divergenzen, Treedepth und BFMI;
• LOO/Pareto-k oder andere prädiktive Modellvergleiche;
• Prior-Sensitivitätsanalysen.

R-hat allein ist kein vollständiger Konvergenznachweis. Maßgeblich sind die modernen rank-normalized R-hat- und ESS-Empfehlungen von Vehtari et al. (2021).

L. Invarianz ist derzeit nicht prüfbar und möglicherweise zirkulär gruppiert

Die Invarianzergebnisse stehen nur in narrativen beziehungsweise abgeleiteten Tabellen; das erzeugende Skript und vollständige Modelloutput fehlen. Falls die Awareness-Gruppen aus denselben TOM-/SAW-Indikatoren gebildet wurden, die zugleich Bestandteil des gemessenen Konstrukts sind, ist die Gruppierung strukturell zirkulär.

Für belastbare Invarianzberichte braucht es mindestens configural, metric und scalar/threshold invariance, Gruppengrößen, estimatorgerechte Restriktionen sowie ΔCFI zusammen mit ΔRMSEA beziehungsweise ΔSRMR und lokalen Missfit-Diagnosen. Eine alleinige ΔCFI-Erzählung ist unzureichend; siehe die Reporting-Übersicht von Putnick & Bornstein (2016).

M. Ordinale, schiefe Items brauchen eine Estimator-Sensitivität

Die Skalen bestehen überwiegend aus stark deckennahen fünfstufigen Items. MLR kann als Robustheitsmodell sinnvoll sein, sollte aber durch eine explizit ordinale Schätzung ergänzt werden. In lavaan führt die Kennzeichnung als ordered zu WLSMV-Logik; die offiziellen Hinweise beschreiben die entsprechende Behandlung kategorialer Endpunkte (lavaan: categorical data, estimators).

Bei EFA wären oblique Rotation und polychorische Korrelationen konsistenter als Varimax auf numerisch behandelten Likert-/Boolean-Items, weil die theoretisch erwarteten Dimensionen korreliert sind.

N. Die Stichproben- und Analyseeinheit ist noch nicht sauber dokumentiert

Der bereitgestellte Rohdatenexport ist modular/long organisiert. In der vorliegenden Datei gibt es 1.803 Zeilen, aber nur 503 Start01-Zeilen; weitere Zeilen gehören zu verschiedenen Fragebogenmodulen und Organisationsbewertungen. Zentrale Skalenitems haben ungefähr 634 bis 652 gültige Werte. Das unterstreicht, dass „Zeilen“, „Antworten“, „Personen“ und „Organisationsevaluationen“ nicht synonym verwendet werden dürfen.

Das Working Paper bezeichnet die Rekrutierung teils als „clustered random sampling“. Die beschriebenen Organisationskontakte, Newsletter, Direktansprachen, Volunteer-Rekrutierung und niedrigen Response-Raten entsprechen jedoch keiner sauber dokumentierten Zufallsstichprobe. Die Arbeit sollte den Prozess als organisationsvermittelte Gelegenheits-/Selbstselektionsstichprobe beschreiben und einen transparenten Flow nach dem Muster der STROBE-Checkliste liefern.

O. Missing Codes und Datenbereinigung sind nicht auditierbar

Das Codebook enthält negative Sentinelwerte wie -1 und -9. Da die vorbereitete RDS-Datei und ihr Erzeugungscode fehlen, lässt sich nicht prüfen, ob alle Missing Codes vor Mittelwert-, Standardisierungs- und Modellschritten korrekt in NA überführt wurden. Dies muss in einer validierten Cleaning-Funktion mit Assertions dokumentiert werden.

P. Explorative Breite und Ergebnisstärke sind nicht aufeinander abgestimmt

Das Repository berichtet über 30 Moderationsanalysen, ohne klar definierte Hypothesenfamilien oder Korrektur multipler Tests. Einzelne p-Werte um .015 bis .039 sind dadurch besonders anfällig für Überinterpretation. Entweder werden wenige primäre Interaktionen präregistriert oder explorative Familien mit Holm/FDR und klarer Kennzeichnung berichtet.

Zudem werden Modelle nach CFI beziehungsweise AIC/BIC gerankt, obwohl sie teilweise andere Indikatoren, Outcomes oder Stichproben verwenden. Fit-Indizes und Informationskriterien sind über solche nicht-nestbaren Daten-/Variablensätze nicht als einfache Rangliste interpretierbar. Für den Dissertationsvergleich sollten dieselben Outcomes, dieselbe Stichprobe und vorab definierte Strukturmodelle verwendet werden; zusätzlich ist out-of-sample Vorhersage sinnvoll.

Konflikte, die vor jeder Ergebnisübernahme geklärt werden müssen

|Behauptung                                        |Repository-/Dateievidenz                                                                                                            |Status           |
|--------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------|-----------------|
|1.337 donors in 26 NPOs                           |Output summiert 1.337 Fälle in 25 Organisationen; die Fälle umfassen auch Nichtspender:innen                                        |korrigieren      |
|Recognition → Trust = .847                        |enthaltenes Bayesian-SEM: .246                                                                                                      |nicht belegt     |
|Trust → Commitment = .602                         |enthaltenes Bayesian-SEM: .447                                                                                                      |nicht belegt     |
|Commitment → Donation = .395                      |enthaltenes Bayesian-SEM: .101; angebliche Intention → Donation .139                                                                |nicht belegt     |
|Commitment-Slope variiert 1.681-fach              |1681 ist eine Random-Slope-Varianz auf quadrierter Euro-Skala                                                                       |falsch           |
|Awareness ist kein Moderator                      |frequentistischer Test nicht signifikant, Bayesian-Output berichtet dagegen ein von null getrenntes Intervall                       |offen/replizieren|
|Multilevel SEM                                    |tatsächlich manifestes `lmer`; lavaan-Modell wird nicht gefittet                                                                    |falsch benannt   |
|Intention im Bayesian-SEM                         |`OF01` ist Rollen-/Statuszählung, keine valide Intention                                                                            |konstruktinvalid |
|16.000 SEM posterior draws verfügbar              |Repository enthält nur Parameter-Punkttabellen, kein vollständiges Draw-/Fit-Objekt                                                 |nicht prüfbar    |
|Awareness-Gruppen spenden etwa 2,8- bis 3-mal mehr|unterschiedliche Dokumente nennen unterschiedliche Mittelwerte; starke Selbstselektion/Confounding                                  |nur deskriptiv   |
|Populationseffekte „kehren sich um“               |externe BMF-Daten und Korrekturskript fehlen; organisationsbezogene Vergleiche identifizieren keine individuellen Populationseffekte|überzogen        |

Was in die Dissertation integriert werden kann

Direkt integrieren – mit vorsichtiger Sprache

1. Messvergleich als Erkenntnis: Trust/Commitment zeigt die robusteste und klarste Struktur; umfangreichere Faircloth-/Romero-Modelle liefern trotz theoretischer Breite schwächeren Fit beziehungsweise geringere Trennschärfe.
2. Theoretischer relationaler Kern: Trust und Commitment sind plausible Vermittlungs- beziehungsweise proximale Motivationskonstrukte zwischen Markensignalen und Intention/Verhalten.
3. Familiarity als schwacher alleiniger Erklärungsansatz: Bekanntheit ist eher Kontext/Exposition als hinreichender psychologischer Mechanismus.
4. Notwendigkeit eines Intention–Behaviour-Modells: Die eher kleinen Outcome-Pfade in den enthaltenen Tabellen und die Messprobleme der bisherigen „Intention“ stützen die explizite, mehrindikatorische Intentionserhebung 2026.
5. Organisationskontext als Boundary-Condition-Frage: nicht als etablierter Effekt, sondern als Begründung für hierarchische beziehungsweise kreuzklassifizierte Modellierung.

Empfohlene Formulierung:

> Die 2025er Explorationsstudie lieferte wiederholte Evidenz für die Messstabilität relationaler Konstrukte, insbesondere Trust und Commitment. Hinweise auf organisations- und spenderbezogene Heterogenität werden aufgrund kleiner und ungleich verteilter Cluster sowie explorativer Mehrfachtests als hypothesengenerierend behandelt und in der Hauptstudie konfirmatorisch geprüft.

Nur nach Reanalyse integrieren

1. Donor-Status/Regelmäßigkeit als Moderator;
2. Awareness-Interaktionen;
3. organisationsspezifische Slopes;
4. Messinvarianz über Organisationen, Erhebungswellen oder echte exogene Gruppen;
5. Bayesianische SEM-Ergebnisse;
6. externe BMF-Vergleiche als Generalisierbarkeits-/Benchmarkanalyse.

Nicht übernehmen

• „1.681-fache“ Commitment-Heterogenität;
• Donation-Tertile als Moderator des gleichen Donation-Outcomes;
• „high-trust organizations can downplay brand“ als Handlungsempfehlung;
• „effects reverse in the population“;
• OF02_Freq als Spendenfrequenz;
• OF01 als Intention;
• die Pfadwerte .847/.602/.395, solange ihre Provenienz nicht rekonstruiert ist;
• „100% complete“, „fully converged“ oder „publication-ready“ als Qualitätsurteil.

Empfohlene Integration in die aktuelle BEBA-Dissertation

Theoretische Architektur

Die neuen Ergebnisse passen am besten in folgende Logik:

Brand-/Organisationssignale → Trust/Commitment bzw. Motivation → Intention → Behaviour

Dabei sollte Trust nicht allein aufgrund eines Fit-Index zwingend an eine einzige Position gesetzt werden. Vergleiche mindestens zwei vorab begründete Modelle auf identischer Stichprobe:

1. Trust-früh: Brand signals → Trust → Commitment/Motivation → Intention → Behaviour;
2. Trust-parallel: Brand signals → Trust und Commitment/Motivation → Intention → Behaviour.

Die 2025er Daten dienen der Modellgenerierung; die 2026er Daten entscheiden konfirmatorisch. Das verhindert, dass datengetriebene Respezifikation und Bestätigung auf derselben Stichprobe vermischt werden.

Hypothesen

Bereits geplante EH9–EH11 sollten nicht durch die fehlerhaften Repository-Moderatoren ersetzt werden. Sinnvoll sind höchstens zwei klar getrennte explorative Erweiterungen:

• EH-Donor: Der Zusammenhang zwischen Marken-/Beziehungsmechanismen und Verhaltensintention unterscheidet sich nach vorherigem Spenderstatus beziehungsweise Regelmäßigkeit. Test als Interaktion im gemeinsamen Modell, nicht als Verhältnis separater Koeffizienten.
• EH-Organisation: Die within-organisation Beziehung zwischen Commitment/Motivation und Spendenverhalten variiert zwischen NPOs. Test nur bei ausreichender Clusterzahl mittels partieller Pooling-Modelle und mit einer vorab definierten Mindestinformation je Cluster.

Awareness sollte als Exposition/Kovariate oder als vorab definierter Moderator getestet werden, nicht als nachträglich erzeugtes Profil aus Messindikatoren, die im selben Modell erneut verwendet werden.

Outcome-Strategie

Die Spendenentscheidung hat mindestens zwei Prozesse und sollte entsprechend modelliert werden:

|Prozess             |Outcome                              |Modellidee                                         |
|--------------------|-------------------------------------|---------------------------------------------------|
|Extensive margin    |spendet ja/nein                      |Logit/Probit beziehungsweise kategoriales SEM      |
|Intensive margin    |positiver Jahresbetrag               |Lognormal oder Gamma mit Link; robuste Sensitivität|
|Zukünftige Intention|mehrindikatorisch `TI04_01`–`TI04_03`|ordinales Messmodell                               |
|Geplanter Betrag    |`OF02_03` separat                    |Hurdle/zweistufig, nicht mit Istbetrag vermischen  |

Eine zweistufige/Hurdle-Analyse verhindert, dass Nichtspenden und Höhe positiver Spenden als derselbe Prozess behandelt werden. Aussagen aus auf donation > 0 gefilterten Gamma-Modellen gelten nur für bereits positive Spender:innen.

Messstrategie

1. 2025 als EFA-/Discovery-Sample, 2026 als CFA-/Confirmatory-Sample;
2. ordinale WLSMV-Haupt- oder Sensitivitätsschätzung für fünfstufige Items;
3. MLR als Robustheitsvergleich;
4. Omega, AVE, HTMT und lokale Residuen gemeinsam berichten;
5. echte Longitudinal-/Welleninvarianz 2025–2026 nur bei identischen Items und vergleichbarer Population;
6. bei ordinaler Invarianz Threshold- statt unreflektierter Intercept-Restriktionen;
7. partielle Invarianz nur theoretisch und lokal begründet.

Multilevel- und Abhängigkeitsstrategie

Vor der Modellierung muss eine eindeutige ID-Struktur hergestellt werden:

• person_id;
• organisation_id;
• evaluation_id;
• Welle/Modul;
• Spendestatus und Datenquelle.

Wenn Personen mehrere Organisationen bewerten, ist ein kreuzklassifiziertes Modell oder eine Clusterkorrektur für Personen und Organisationen erforderlich. Organisationsaggregate müssen extern, leave-one-out oder in einem expliziten latent/group-level Modell definiert werden. „Organisationsgröße“ darf nicht als Anzahl der Survey-Zeilen operationalisiert werden.

Bayesianische Strategie

Wenn Bayesian SEM/GLM Teil der Dissertation wird, sollte der Workflow vorab festlegen:

1. prior predictive checks;
2. fachlich begründete schwach informative Priors;
3. vier oder mehr Ketten mit dokumentierter Initialisierung und Seed;
4. rank-normalized R-hat, bulk/tail ESS, MCSE;
5. Divergenzen, Treedepth, BFMI;
6. posterior predictive checks für jedes Outcome;
7. LOO/Pareto-k für Modelle mit identischer Zielvariable und Stichprobe;
8. Prior- und Likelihood-Sensitivitäten;
9. vollständige Speicherung der Modelle und Draws.

Sprache der Schlussfolgerungen

Die Daten sind überwiegend cross-sectional und self-report. Daher:

|Vermeiden                               |Bevorzugen                                                          |
|----------------------------------------|--------------------------------------------------------------------|
|„X drives Y“                            |„X is associated with Y“                                            |
|„mediates“ ohne zeitliche Identifikation|„statistical indirect association“                                  |
|„causes higher donations“               |„predicts/reports higher donation amounts, conditional on the model“|
|„population effect“                     |„sample estimate“ beziehungsweise „external benchmark discrepancy“  |
|„moderator“ aus getrennten Koeffizienten|„descriptive subgroup difference“, bis Interaktion getestet ist     |

Priorisierter Reanalyseplan

Priorität 0 – vor jeder Übernahme in Text oder Tabelle

1. Vollständige Datenaufbereitung und alle Hauptskripte versionieren.
2. Eindeutige Datenwörterbuch-Mappingtabelle erstellen: theoretisches Konstrukt → Item → Codierung → Missing Rule → Analyseeinheit.
3. OF01 aus der Intention entfernen und die Pfade neu schätzen.
4. OF02_Freq entfernen oder korrekt umbenennen.
5. alle Organisations- und N-Angaben aus einer einzigen maschinenlesbaren Stichprobenübersicht erzeugen.
6. Provenienz der Werte .847/.602/.395 klären oder aus allen Texten streichen.
7. die „1681-fold“-Aussage und alle outcome-definierten Tertilmoderationen entfernen.

Priorität 1 – für dissertationsfähige Hauptbefunde

1. Hauptmodelle 2026 präregistrieren; 2025 nur zur Spezifikation verwenden.
2. EFA/CFA beziehungsweise 2025/2026 strikt trennen.
3. ordinale und robuste Schätzer als Sensitivität fitten.
4. binäre Spendenentscheidung und positive Betragshöhe getrennt modellieren.
5. wiederholte Bewertungen derselben Person und Organisationscluster gemeinsam berücksichtigen.
6. nur wenige theoriegeleitete Interaktionen testen; marginale Effekte mit Intervallen berichten.
7. Missingness, Ausreißer/Influence und Modellannahmen transparent dokumentieren.

Priorität 2 – für Publikationsstärke

1. vollständige reproduzierbare Pipeline mit Lockfile, Seeds und Tests;
2. multiverse-/specification-curve-artige Robustheit für zentrale Entscheidungen;
3. out-of-sample oder cross-validierte Modellbewertung;
4. externe Organisationsdaten nur über nachvollziehbare Schlüssel und klar definierte Zielpopulation anbinden;
5. offene, aber datenschutzkonforme Replikationsartefakte und synthetische Beispieldaten bereitstellen.

Minimaler Ergebnisstandard für jedes zentrale Modell

Jede Ergebnistabelle sollte gemeinsam ausweisen:

• Datenversion, Commit und Skript;
• Analyseeinheit, Personen-N, Evaluationen-N und Organisations-N;
• vollständige Ein-/Ausschlussregeln;
• Missing-Data-Behandlung;
• Schätzer, Link/Likelihood und Priors;
• standardisierte und unstandardisierte Effekte;
• 95%-Intervall, nicht nur Sternchen/p-Wert;
• Fit beziehungsweise Posterior-/Residualdiagnostik;
• Sensitivitätsmodelle;
• klare Kennzeichnung als konfirmatorisch oder explorativ.

Empfohlene Kapitelplatzierung

|Dissertationsabschnitt|Integration                                                                                                              |
|----------------------|-------------------------------------------------------------------------------------------------------------------------|
|Theorie               |Trust/Commitment als relationaler Mechanismus; Awareness als Exposition/Kontext; keine starken Repository-Kausalaussagen.|
|Pilot-/Vorstudie      |2025er Modell- und Skalenvergleich, offen als explorativ; Boenigk-Stabilität und Schwächen komplexerer Skalen.           |
|Methoden Hauptstudie  |präregistrierte BEBA-Modelle, korrekte Intention, zweistufiges Behaviour-Outcome, ordinal/multilevel Sensitivität.       |
|Ergebnisse            |Hauptmodelle 2026; Donor-/Organisationsmoderation nur bei formalen Interaktionstests und ausreichender Information.      |
|Diskussion            |Replikation/Nichtreplikation von Familiarity, Trust/Commitment und Intention-Gap; Generalisierbarkeit vorsichtig.        |
|Appendix/Repository   |komplette Pipeline, Datenfluss, Codebook, Konvergenz- und Robustheitsdiagnostik.                                         |

Schlussfolgerung

Das Repository stärkt vor allem eine schlankere und theoretisch klarere Dissertation: Der relationale Kern aus Trust und Commitment ist belastbarer als die breiteren, teilweise überlappenden Markenmodelle; Awareness allein erklärt wenig; Intention und Behaviour müssen sauberer gemessen und getrennt modelliert werden. Die spektakuläreren neuen Aussagen zu Random Slopes, organisationsbezogener Suppression, „Population Reversal“ und großen Moderationseffekten sind derzeit nicht ausreichend identifiziert oder dokumentiert.

Die beste wissenschaftliche Nutzung ist daher nicht, diese Claims in die Dissertation zu „integrieren“, sondern sie in präzise konfirmatorische Fragen für 2026 zu übersetzen. Damit gewinnt die Dissertation an Rigor, ohne die explorative Arbeit von 2025 zu verlieren.

Geprüfte lokale Quellen

• GitHub-Repository GeraldCzech/R-Pipeline, Commit ae88d939...
• skalenkonstruktion_2025-05-16_19-44 … .xlsx
• Skalenanalyse_Ergebnisse_neu.txt
• rdata_SpendenOrganisationen_2025-05-16_19-44.csv
• Zusammenfassung der Skalenanalyse.docx
• 20250321-Proposal-EN-Einreichversion.pdf
• ERNOP-PHD-Workshop-2025-Gerald-Czech.pdf
• WorkingPaper-2025-Gerald-Czech-vers-09-2025.docx
