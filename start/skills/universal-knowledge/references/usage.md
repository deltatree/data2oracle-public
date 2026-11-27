# Bedienung

Diese Anleitung richtet sich an Personen mit laufendem UKE-Dienst und Claude Code.
Ein Skill ist eine wiederverwendbare Rechercheanleitung mit ausführbaren Helfern.
Er benötigt lokale Kommandoausführung und Zugriff auf die Container-Laufzeit.
Die Suche läuft auf dem gewählten UKE-Rechner; ausgewählte Belegtexte werden bei der Antworterstellung an Claude übertragen.

## In Claude Code installieren

Führe diese Befehle im heruntergeladenen Projektordner aus.
Sichere vorher eigene Änderungen in gleichnamigen installierten Skill-Dateien; diese werden beim Kopieren überschrieben.

```sh
mkdir -p "$HOME/.claude/skills"
cp -R skills/universal-knowledge "$HOME/.claude/skills/"
sh "$HOME/.claude/skills/universal-knowledge/scripts/context.sh" "Welche Themen enthalten meine Dokumente?" --mode rerank --budget 6000
```

Der Kopierbefehl installiert oder aktualisiert ausschließlich diesen Skill.
Aktualisiere zuvor das Anwendungspaket. Lade danach den Skill in einer neuen Assistentensitzung.
Bei MCP-Nutzung lade die Verbindung in Continue neu, damit neue Werkzeuge und Serveranweisungen erscheinen.
Eine alte persönliche Skill-Kopie enthält weiterhin den bisherigen Suchablauf, auch nach einem Serverupdate.
Die letzte Zeile prüft den tatsächlichen Werkzeugzugriff.
`--mode rerank` sortiert gefundene Passagen zusätzlich nach ihrer Passung zur Frage.
Der globale Suchstandard bleibt unverändert.
Nutze den Graphmodus zusätzlich für Fragen nach Beziehungen zwischen Aussagen.
Starte danach eine lokale Claude-Code-Sitzung und frage:

```text
/universal-knowledge Welche Fristen und Ausnahmen nennen meine Dokumente? Belege jede Aussage und benenne fehlende Informationen.
```

Der lokale Code-Reiter der Claude-Desktop-App lädt dieselben persönlichen Skills.
Wähle dort eine lokale Sitzung und verwende denselben Aufruf.
Der gewöhnliche Chat oder Browser erhält durch Hochladen eines Skills keinen Zugriff auf deinen lokalen Dienst.
Dafür wäre zusätzlich eine ausdrücklich eingerichtete Werkzeugverbindung erforderlich.

## Laufzeit und Dienst auswählen

Standardwerte sind `docker` und `uke-engine`.
Für andere Werte starte Claude Code aus derselben vorbereiteten Shell:

```sh
export UKE_RUNTIME=podman
export UKE_CONTAINER=uke-engine
claude
```

Im lokalen Code-Reiter hinterlege abweichende Werte in der Sitzungsumgebung.
Eine vorherige Terminal-Einstellung wird dort nicht zwingend übernommen.
UKE verändert keine persönlichen Claude-Einstellungen.

## Vorhandenen entfernten Dienst nutzen

Nutze diesen Weg, wenn dein Mac die benötigte Linux-Schutzfunktion noch nicht bereitstellt.
Voraussetzung sind ein bereits freigegebener laufender UKE-Dienst und funktionierender SSH-Zugriff auf dessen Rechner.
Der SSH-Benutzer benötigt bereits Zugriff auf den dortigen Docker-Dienst.
Auf dem Mac genügen Claude Code, der Docker-Kommandozeilenclient und der oben kopierte Skill-Ordner.
Ein lokaler UKE-Container ist für diesen Weg nicht erforderlich.

Ersetze `benutzer@server.example` durch deine vorhandene SSH-Adresse.
Ersetze bei Bedarf `uke-engine` durch den bestehenden Dienstnamen.
Führe den folgenden Block auf dem Mac aus:

```sh
(
  set -e
  unset DOCKER_CONTEXT
  export DOCKER_HOST=ssh://benutzer@server.example
  export UKE_RUNTIME=docker
  export UKE_CONTAINER=uke-engine
  docker exec "$UKE_CONTAINER" uke doctor --quick
  sh "$HOME/.claude/skills/universal-knowledge/scripts/context.sh" "Welche Themen enthalten meine Dokumente?" --mode rerank --budget 6000
  claude
)
```

Prüfe die beiden Abfrageausgaben, bevor du in Claude recherchierst.
Die Klammern begrenzen diese Verbindungswahl auf die gestartete Shell und deren Claude-Sitzung.
`DOCKER_CONTEXT` wird dort entfernt, weil es sonst die Zieladresse übersteuern könnte.
Die [Docker-Anleitung für SSH](https://docs.docker.com/engine/security/protect-access/) beschreibt diese Verbindung.
Die [Variablenreferenz](https://docs.docker.com/reference/cli/docker/#environment-variables) erklärt die Rangfolge der Verbindungswahl.

Die Befehle aktualisieren den entfernten Dienst nicht.
Sie verwenden dessen vorhandenen Programmstand; neu veröffentlichte Verbesserungen werden dort nicht automatisch aktiv.
Übergebe in dieser Umgebung keine Mac-Dateipfade an `tools/run.sh` oder `tools/prepare-models.sh`.
Eingebundene Dateipfade beziehen sich bei einem entfernten Docker-Dienst auf den entfernten Rechner.
Die Dokumente und Modelle bleiben dort; Frage und Antwortbelege passieren die verschlüsselte SSH-Verbindung.
Claude überträgt die ausgewählten Belegtexte anschließend an seinen Modelldienst.
Der UKE-Container behält seine eigene Netzwerksperre.
Die Docker-Verbindung besitzt jedoch umfassende Verwaltungsrechte; verwende sie ausschließlich mit deinem freigegebenen Eigentümerkonto.

Im lokalen Code-Reiter müssen dieselben Verbindungsvariablen in dessen Sitzungsumgebung stehen.
Beende die entfernte Claude-Sitzung, bevor du auf lokalen Betrieb wechselst.
Wähle anschließend ausdrücklich die lokale Laufzeit und prüfe dort zuerst `sh tools/check-runtime.sh`.
Erst danach folgen lokale Modellvorbereitung, Start und `doctor --deep`.

## Einzelne Werkzeuge aufrufen

Die folgenden Befehle funktionieren unabhängig vom aktuellen Arbeitsordner:

```sh
sh "$HOME/.claude/skills/universal-knowledge/scripts/search.sh" "NX-410" --mode hybrid
sh "$HOME/.claude/skills/universal-knowledge/scripts/context.sh" "Wo liegen die Sicherungen?" --mode rerank --budget 6000 --format markdown
sh "$HOME/.claude/skills/universal-knowledge/scripts/expand.sh" --ref REFERENZ --window 4
sh "$HOME/.claude/skills/universal-knowledge/scripts/sources.sh" --ref REFERENZ
sh "$HOME/.claude/skills/universal-knowledge/scripts/verify.sh" --statement '<urn:rex> <urn:type> <urn:Animal> .'
```

Ersetze `REFERENZ` durch einen tatsächlich erhaltenen Belegbezeichner.
Ein Fehler beim Werkzeugaufruf ist keine erfolgreiche Recherche.
Wenn die Sitzung keine Kommandos ausführen darf, benenne diese Grenze ausdrücklich.

## Weitere Agenten

Codex unterstützt beispielsweise `.agents/skills/universal-knowledge`.
Installiere den gesamten Ordner einschließlich `scripts` und `references`.
Löse Skriptpfade immer gegen den tatsächlichen Installationsordner auf.
Setze `UKE_SKILL_DIR` ausdrücklich auf den absoluten Installationspfad; der Assistent setzt diese Variable nicht automatisch.

Offizielle Anleitungen: [Claude-Skills](https://code.claude.com/docs/en/skills) und [lokaler Code-Reiter](https://code.claude.com/docs/en/desktop).

## Begrenzte Nachrecherche und neue Folgerungen

`uke research "Projekt Nordlicht" --question "Fristen für Projekt Nordlicht" --question "Ausnahmen für Projekt Nordlicht" --mode bm25 --budget 12000` recherchiert ausdrücklich genannte Teilfragen.
Der Helfer `scripts/research.sh` führt denselben Befehl im bestehenden Container aus.
Ohne `--question` bleibt die gesamte Frage eine Teilfrage.
Claude darf passende Teilfragen ausdrücklich übergeben; der lokale Dienst zerlegt keine freie Sprache selbst.
Jede Teilfrage muss ihr Thema selbst nennen. Die Gesamtfrage ergänzt den Suchtext nicht automatisch.
`--path` begrenzt sämtliche Such- und Folgeaufrufe auf den angegebenen Originalpfad.
Die Ausgabe ordnet Belege jeder Teilfrage zu und nennt offene Fragen sowie erreichte Grenzen.
Nachbarsuche und Ausnahmesuche ersetzen keine Vollständigkeitsprüfung.
Dokumentanweisungen bleiben unvertrauenswürdiger Quellentext.

Die vier getrennten Schalter heißen `research_followups`, `ocr_orientation`, `table_context` und `derived_verification`.
Alle stehen zunächst auf `false`.
`research_followups` aktiviert zusätzliche automatische Nachrecherche.
Bis zu acht ausdrückliche Teilfragen funktionieren auch bei ausgeschaltetem Schalter.
Die gemeinsame Recherche umfasst höchstens 32 Aufrufe und 400000 JSON-Bytes übertragene Fundstellen.
Bestehende Such- und Prozessgrenzen gelten weiter.
`ocr_orientation` vergleicht vier Drehungen; die Grenze zählt jeden OCR-Vorgang und dessen Pixel.
`table_context` hält Tabellenkopf, Einheit im Kopf und leere Zellen bei jeder Datenzeile.
Ohne ausdrücklich belegten Kopf kennzeichnet `table_header_status=assumed_first_row` die erste Zeile als Annahme.
Die erste Zeile bleibt erhalten; Kopf- und Einheitenzuordnung benötigen dann eine Prüfung.
Überlange Zeilen werden abgewiesen; verbundene Zellen bleiben ausdrücklich ungeprüft.
Native PDF-Erkennung unterstützt eindeutige, ausgerichtete Zahlenraster mit einem Textkopf.
Komplexe Layouts und mehrzeilige Tabellenköpfe benötigen weiterhin eine gesonderte Prüfung.
`derived_verification` prüft im Modus `verify` zusätzliche RDF-Aussagen aus den endgültigen Belegen.
RDF beschreibt Beziehungen als Subjekt, Eigenschaft und Objekt.
Nur vorhandene Basisschemaregeln und konfigurierte `ontology_files` liefern Ableitungsregeln.
Der unabhängige Lean-Prüfer kontrolliert den Nachweis; Quellenwahrheit ist damit nicht bewiesen.
Bei fehlenden Regeln, Konflikten oder fehlendem Ausgabebudget bleibt die Aussage ungeprüft.

Nach Änderungen an `ocr_orientation` oder `table_context` ist `uke reindex` erforderlich.
Vor der Aktivierung Programm, Konfiguration und Wissensgeneration gemeinsam sichern.
Zur Rücknahme gemeinsam auf diese drei kompatiblen Stände zurückkehren.

### Referenzvorlage in Schema 3

Bei genau einer Teilfrage kann die Ausgabe `"references":"evidence[].ref"` statt einer wiederholten Referenzliste enthalten.
Das bedeutet: Alle ausgegebenen Belege gehören zu dieser Teilfrage.
Die Vorlage wird nur verwendet, wenn die vollständige Zuordnung eindeutig ist.
`"query_ref":"query"` verweist auf die Frage im obersten Feld `query`.
Diese Darstellung gilt für JSON, Markdown und Text.
Mehrere Teilfragen behalten ihre ausdrücklichen `refs`-Listen und Fragetexte.
Die Python-Rückgabe von `research()` behält ebenfalls ausdrückliche Listen und Fragetexte.
Das Bytebudget zählt die tatsächlich gerenderte Ausgabe einschließlich des abschließenden Zeilenumbruchs.

## Fortsetzbare Quellenprüfung

`search` liefert ausgewählte Fundstellen, keine vollständige Quellenübersicht.
`discover` findet Dokumentpfade anhand von Wörtern, unabhängig von bisherigen Suchtreffern.
Ohne Frage zeigt es alle bekannten Pfade, einschließlich leerer und ausgesonderter Dokumente.
Ein Treffer beweist keinen fachlichen Zusammenhang. Prüfe diesen beim Lesen.
`discover.reference` enthält nur Referenzkennung, Absatzposition, Originalpfad, Version und Prüfsumme.
Lade den Volltext und die genaue Fundstelle mit `read_document` nach.
So bleibt die Dokumentübersicht auch bei einzelnen übergroßen Absätzen erreichbar.
Die Lektüre eines übergroßen Absatzes meldet weiterhin einen kontrollierten Fehler.

```sh
uke discover "Frist Ausnahme"
uke discover
uke discover "Frist" --path /data/documents/richtlinie.txt
uke read_document --path /data/documents/richtlinie.txt --limit 20
```

Die Antwort enthält `items`, `total`, `remaining`, `next_offset` und `snapshot`.
`remaining` zählt noch ungelesene technische Einträge, keine ungeklärten fachlichen Aussagen.
Übernimm `next_offset` und `snapshot` aus der vorherigen Antwort:

```sh
uke discover "Frist Ausnahme" --offset 20 --snapshot SNAPSHOT_AUS_DER_ANTWORT
uke read_document --path /data/documents/richtlinie.txt --offset 20 --snapshot SNAPSHOT_AUS_DER_ANTWORT
```

Behalte Frage und Pfad bei. Der Snapshot bindet die Fortsetzung an Auftrag und Indexstand.
Bei einer Änderung meldet der Dienst einen erforderlichen Neustart.
Beginne dann ohne Snapshot bei Position null und gleiche deine Quellenliste ab.
Beende das Blättern erst bei `next_offset: null` und `remaining: 0`.
Jeder Aufruf liefert höchstens 100 Einträge und 200000 Bytes vollständige JSON-Ausgabe.
Bei der Bytegrenze zeigt `next_offset` auf den ersten noch fehlenden Eintrag.
Ein einzelner übergroßer Eintrag erzeugt einen Fehler; er wird niemals still übersprungen.

`read_document` liest ausschließlich gespeicherte Absätze bekannter Originalpfade.
Aliasdateien behalten ihren gewählten Pfad und ihre Version.
Die Herkunft jedes Absatzes entspricht den bestehenden Suchbelegen.
`index_status` zeigt Importzustände; `limits.import` nennt die eingestellten Importgrenzen.
Leere, offene und ausgesonderte Dokumente garantieren keine vollständige Erfassung ihres Originals.
Alle Indexseiten zu lesen garantiert außerdem keine semantisch vollständige Antwort.
Prüfe Varianten, Gegenbelege und jede Tatsachenaussage; nenne offene Punkte ausdrücklich.
Die Zahl fachlich benötigter Rechercherunden ist nicht pauschal begrenzt.

Für installierte Skills stehen dieselben Befehle bereit:

```sh
sh "${UKE_SKILL_DIR}/scripts/discover.sh" "Frist Ausnahme"
sh "${UKE_SKILL_DIR}/scripts/read_document.sh" --path /data/documents/richtlinie.txt
```

Die bisherige automatische Ausnahmesuche bleibt auf ihre Ausgangsquellen begrenzt.
Ohne Nutzerbeschränkung verwende `discover` für zusätzliche Dokumente ohne `--path`; dafür ist keine neue Konfiguration nötig.
Behalte ausdrücklich gesetzte Pfade und Quellenumfänge bei und nenne die dadurch begrenzte Abdeckung.
