# Manifest der latenten Brand-Equity-Konstrukte

**Projekt:** Dissertation „Impact of Brand Equity on the resources of nonprofit organisations in Austria“  
**Fassung:** 1.0  
**Stand:** 22. August 2026  
**Zweck:** Verbindliche Nomenklatur der theoretischen und im SEM spezifizierten Brand-Equity-Konstrukte

## 1. Benennungsregeln

1. Die englische Originalbezeichnung ist der verbindliche Konstruktname. Die deutsche Bezeichnung dient der Erläuterung.
2. `Brand Equity` wird im Deutschen als **wahrnehmungsbasierte Markenwertigkeit** erläutert, um eine Verwechslung mit dem finanziellen Markenwert zu vermeiden.
3. Ein Präfix kennzeichnet die Modellfamilie: `FC_` = Faircloth, `BO_` = Boenigk und Becker, `RO_` = Rios Romero et al.
4. Erstordnungsfaktoren, Faktoren höherer Ordnung und beobachtete Variablen werden terminologisch getrennt.
5. Technische Re-Spezifikationen der Dissertation dürfen nicht als unveränderte Originalmodelle bezeichnet werden.

## 2. Faircloth-Modell

Faircloth modelliert **Brand Personality**, **Brand Image** und **Brand Awareness** als Antezedenzien der **Nonprofit Brand Equity**.

| Code | Verbindliche englische Bezeichnung | Deutsche Erläuterung | Ebene |
|---|---|---|---|
| `FC_BR` | Brand Respect | Markenrespekt | erste Ordnung |
| `FC_BD` | Brand Differentiation | Markendifferenzierung | erste Ordnung |
| `FC_BP` | Brand Personality | Markenpersönlichkeit | zweite Ordnung |
| `FC_BC` | Brand Character | Markencharakter | erste Ordnung |
| `FC_BS` | Brand Scale | Markenstatur bzw. wahrgenommene Größe/Stärke | erste Ordnung |
| `FC_BI` | Brand Image | Markenimage | zweite Ordnung |
| `FC_RC` | Brand Recall and Recognition | Markenerinnerung und Markenwiedererkennung | erste Ordnung |
| `FC_BF` | Brand Familiarity | Markenvertrautheit | erste Ordnung |
| `FC_BA` | Brand Awareness | Markenbekanntheit | zweite Ordnung |
| `FC_BE` | Nonprofit Brand Equity | wahrnehmungsbasierte Nonprofit-Markenwertigkeit | höhere Ordnung |

### Struktur

```text
FC_BP =~ FC_BR + FC_BD
FC_BI =~ FC_BC + FC_BS
FC_BA =~ FC_RC + FC_BF
FC_BE =~ FC_BP + FC_BI + FC_BA
```

### Verbindliche Korrekturen

- `FC_BR` bedeutet **Brand Respect**, nicht Brand Recall.
- `FC_BC` bedeutet **Brand Character**, nicht Brand Commitment.
- `FC_RC` bezeichnet **Brand Recall and Recognition**.

## 3. Boenigk-und-Becker-Modell

Die drei theoretischen Dimensionen sind **Nonprofit Brand Awareness**, **Nonprofit Brand Trust** und **Nonprofit Brand Commitment**.

| Code | Verbindliche englische Bezeichnung | Deutsche Erläuterung | Status |
|---|---|---|---|
| `BO_BF` | Brand Familiarity | Markenvertrautheit | technischer Teilfaktor von Brand Awareness |
| `BO_RC` | Brand Recall and Recognition | Markenerinnerung und Markenwiedererkennung | technischer Teilfaktor von Brand Awareness |
| `BO_TR` | Nonprofit Brand Trust | Vertrauen in die Nonprofit-Marke | theoretische Kerndimension |
| `BO_CO` | Nonprofit Brand Commitment | Bindung an die Nonprofit-Marke | theoretische Kerndimension |
| `BO_BE` | Nonprofit Brand Equity | stakeholderbasierte Nonprofit-Markenwertigkeit | übergeordneter Faktor der Dissertation |

### Struktur der SEM-Umsetzung

```text
BO_TR =~ B101_01 + B101_02 + B101_03
BO_CO =~ B102_01 + B102_02 + B102_03
BO_BF =~ FC03_01 + FC03_02 + FC03_03
BO_RC =~ TOM + SAW
BO_BE =~ BO_TR + BO_CO + BO_BF + BO_RC
```

`BO_BF` und `BO_RC` sind getrennte latente Faktoren der SEM-Umsetzung. Inhaltlich operationalisieren sie gemeinsam **Nonprofit Brand Awareness**.

## 4. Rios-Romero-Modell

Das konzeptuelle Modell unterscheidet **Brand Familiarity**, **Brand Associations** und **Brand Commitment** als Quellen der **Donor-Based Brand Equity**.

| Code | Verbindliche englische Bezeichnung | Deutsche Erläuterung | Ebene/Status |
|---|---|---|---|
| `RO_BF` | Brand Familiarity / Recall and Recognition | Markenvertrautheit bzw. Erinnerung und Wiedererkennung | erste Ordnung |
| `RO_BS` | Brand Strength | Markenstärke und Wissen über die NGO | erste Ordnung |
| `RO_BA` | Brand Familiarity | übergeordnete Vertrautheitsdimension | zweite Ordnung; Code semantisch missverständlich |
| `RO_BI` | Brand Identification | Identifikation mit der NGO-Marke | erste Ordnung |
| `RO_BW` | Brand Authenticity | Markenauthentizität | erste Ordnung |
| `RO_BD` | Brand Differentiation | Markendifferenzierung | erste Ordnung |
| `RO_BR` | Brand Reputation | Markenreputation | erste Ordnung |
| `RO_BP` | Brand Associations | Markenassoziationen | zweite Ordnung; Code semantisch missverständlich |
| `RO_AC` | Attitudinal Commitment | einstellungsbezogene Markenbindung | erste Ordnung |
| `RO_EC` | Emotional Commitment | emotionale Markenbindung | erste Ordnung |
| `RO_BC` | Brand Commitment | übergeordnete Markenbindung | zweite Ordnung |
| `RO_ID` | Intention to Donate | Spenden-, Fortsetzungs- und Weiterempfehlungsintention | latentes Zielkonstrukt |
| `RO_BE` | Donor-Based Brand Equity | spender:innenbasierte Brand Equity | in der Dissertation re-spezifizierter Faktor höherer Ordnung |

### Empfohlene semantische Codes

| Bestehender Code | Empfohlener Code | Begründung |
|---|---|---|
| `RO_BA` | `RO_FAM` | Das Konstrukt heißt bei Rios Romero et al. Brand Familiarity, nicht Brand Awareness. |
| `RO_BP` | `RO_ASSOC` | Das Konstrukt bündelt Associations, nicht Brand Personality. |
| `RO_ID` | `RO_INT` | Die Items messen Intention to Donate, nicht Brand Identification. |

### Abgrenzung vom publizierten Originalmodell

Im publizierten PLS-Modell wird **Donor-Based Brand Equity** unmittelbar durch sieben `ID`-Items operationalisiert. Diese Items messen Spenden-, Fortsetzungs- und Weiterempfehlungsintention. Eine Spezifikation

```text
RO_BE =~ RO_BC + RO_BP + RO_BI + RO_BA
```

ist daher eine eigenständige Re-Spezifikation der Dissertation und nicht das unveränderte Originalmodell. `RO_ID` darf keinesfalls als Brand Identification bezeichnet werden; Brand Identification ist `RO_BI`.

## 5. Prozessmodell nach Chatzipanagiotou, Veloutsou und Christodoulides

Consumer-Based Brand Equity wird als dynamischer, sequenzieller Prozess mit drei Blöcken und insgesamt 15 Knoten modelliert.

### Brand Building Block

| Originalbezeichnung | Deutsche Erläuterung |
|---|---|
| Brand Heritage | Markenerbe bzw. Markentradition |
| Brand Nostalgia | Markennostalgie |
| Brand Personality Appeal | Attraktivität der Markenpersönlichkeit |
| Perceived Quality | wahrgenommene Qualität |
| Brand Leadership | Markenführerschaft |
| Brand Competitive Advantage | wahrgenommener Wettbewerbsvorteil der Marke |

### Brand Understanding Block

| Originalbezeichnung | Deutsche Erläuterung |
|---|---|
| Brand Awareness | Markenbekanntheit |
| Brand Associations | Markenassoziationen |
| Brand Reputation | Markenreputation |
| Brand Self-Connection | Selbst-Marken-Verbindung |

### Brand Relationship Block

| Originalbezeichnung | Deutsche Erläuterung |
|---|---|
| Brand Partner Quality | wahrgenommene Qualität der Marke als Beziehungspartnerin |
| Brand Intimacy | psychologische Nähe bzw. Markenintimität |
| Brand Trust | Markenvertrauen |
| Brand Relevance | persönliche und soziale Markenrelevanz |

### Ergebnis

| Originalbezeichnung | Deutsche Erläuterung |
|---|---|
| Overall Brand Equity | gesamte wahrnehmungsbasierte Markenwertigkeit |

Die Bezeichnungen **Brand Building Block**, **Brand Understanding Block** und **Brand Relationship Block** sind zunächst Prozessblöcke. Sie dürfen nur dann als latente Faktoren bezeichnet werden, wenn sie im konkreten Messmodell ausdrücklich als Faktoren höherer Ordnung spezifiziert werden.

## 6. BEBA-Adaption der Dissertation

Die BEBA-Synthese übernimmt die Prozesslogik, verwendet jedoch eine nonprofit- und verhaltensbezogen angepasste Auswahl latenter Markenkonstrukte.

| Prozessstufe | Latente Konstrukte |
|---|---|
| Brand Building | Brand Familiarity; Brand Image; Brand Personality |
| Brand Understanding | Brand Differentiation |
| Brand Relationships | Brand Trust; Brand Commitment; Brand Identification |

Diese sieben Konstrukte sind die latenten Brand-Equity-Kernkonstrukte der BEBA-Adaption:

1. **Brand Familiarity** — Markenvertrautheit
2. **Brand Image** — Markenimage
3. **Brand Personality** — Markenpersönlichkeit
4. **Brand Differentiation** — Markendifferenzierung
5. **Brand Trust** — Markenvertrauen
6. **Brand Commitment** — Markenbindung
7. **Brand Identification** — Markenidentifikation

Motivationale und verhaltensbezogene Konstrukte wie Attitude, Subjective Norm, Perceived Behavioral Control, Moral Norm, Intention, Constraints, Habit, Knowledge und Salience sind Bestandteile der gesamten BEBA, aber keine Brand-Equity-Konstrukte im engeren Sinn.

## 7. Nichtlatente Awareness-Variablen

Folgende Variablen sind keine eigenständigen latenten Brand-Equity-Konstrukte:

| Variable | Status |
|---|---|
| `BA_A` | beobachtete bzw. abgeleitete Awareness-Variable |
| `BA_T` | beobachtete bzw. abgeleitete Awareness-Variable |
| `BA_S` | beobachtete bzw. abgeleitete Awareness-Variable |
| `BA_F` | beobachtete bzw. abgeleitete Awareness-Variable |
| `TOM` | beobachteter Top-of-Mind-Indikator |
| `SAW` | beobachteter Awareness-/Wiedererkennungsindikator |

`TOM` und `SAW` können als manifeste Indikatoren der latenten Faktoren `FC_RC` und `BO_RC` verwendet werden. Dadurch werden sie selbst nicht zu latenten Variablen.

## 8. Zitierfähige Kurzform

> Die Untersuchung unterscheidet zwischen kognitiven Zugangsgrößen der Marke, evaluativen Markenwahrnehmungen und relationalen Markenkonstrukten. Die BEBA-Adaption operationalisiert Brand Equity über Brand Familiarity, Brand Image, Brand Personality, Brand Differentiation, Brand Trust, Brand Commitment und Brand Identification und positioniert diese Konstrukte kausal vor Motivation, Intention und Verhalten.

## 9. Quellen

- Boenigk, S., & Becker, A. (2016). *Toward the Importance of Nonprofit Brand Equity: Results from a Study of German Nonprofit Organizations*. Nonprofit Management & Leadership, 27(2), 181–198. https://doi.org/10.1002/nml.21233
- Chatzipanagiotou, K., Veloutsou, C., & Christodoulides, G. (2016). *Decoding the Complexity of the Consumer-Based Brand Equity Process*. Journal of Business Research, 69(11), 5479–5486. https://doi.org/10.1016/j.jbusres.2016.04.159
- Faircloth, J. B. (2005). *Factors Influencing Nonprofit Resource Provider Support Decisions: Applying the Brand Equity Concept to Nonprofits*. Journal of Marketing Theory and Practice, 13(3), 1–15. https://doi.org/10.1080/10696679.2005.11658546
- Rios Romero, M. J., Abril, C., & Urquia-Grande, E. (2023). *Insights on NGO Brand Equity: A Donor-Based Brand Equity Model*. European Journal of Management and Business Economics, 32(4), 452–468. https://doi.org/10.1108/EJMBE-08-2022-0261

---

**Status des Manifests:** Dieses Dokument legt die Standardbezeichnungen für Datendokumentation, Analysecode, Tabellen und Dissertationstext fest. Abweichungen sind als alternative Spezifikationen oder technische Hilfsvariablen ausdrücklich zu kennzeichnen.
