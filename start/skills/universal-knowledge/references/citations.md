# Genaue Zitate und Ausschnittbelege

Suche zunächst mit dem Kontexthelfer. Übernimm `ref`, Originalpfad und Inhaltsprüfsumme aus dessen Ergebnis.
Führe danach den Zitathelfer aus. Verwende den tatsächlichen Installationspfad der Rechercheanleitung.

```sh
UKE_RUNTIME=podman UKE_CONTAINER=uke-engine sh "${UKE_SKILL_DIR}/scripts/cite.sh" \
  --ref REFERENZ --path ORIGINALPFAD --expected-hash PRUEFSUMME \
  --quote "Wörtlicher Ausschnitt" --screenshot --format markdown
```

Ersetze die Platzhalter durch erhaltene Werte. Übergib jedes Argument einzeln und sicher maskiert.
Ohne `--quote` prüft der Helfer den gesamten gefundenen Textabschnitt.
Mit `--occurrence 2` wählst du beispielsweise das zweite gleiche Vorkommen im Textabschnitt.
Bei identischen Quelldateien ist `--path` erforderlich.
`--expected-hash` schützt gegen eine inzwischen geänderte Dokumentfassung.

Die Prüfung vergleicht den Wortlaut mit der gespeicherten Fundstelle und die Inhaltsprüfsumme mit einer begrenzten Originalkopie.
Diese vorübergehende Kopie wird danach gelöscht. Die Prüfung beweist keine sachliche Wahrheit der Quelle.
Bei Fehlern darf der Assistent keine erfolgreiche Prüfung behaupten.
Prüfe den vollständigen Satz mit allen tragenden Bedingungen. Ein geprüftes Einzelwort belegt keine umfassendere Aussage.
Vorhandene Suchdaten bleiben nutzbar. Diese Zitaterweiterung erfordert kein erneutes Einlesen.

## Positionen richtig lesen

Für PDF-Zitate stammen gedruckte Seitenangaben ausschließlich aus `cite`.
`location.page` eines Suchtreffers bleibt die technische PDF-Position ab eins.
`page` mit `page_basis=pdf_page` behält diese bisherige Bedeutung.

| Angabe | Bedeutung |
|---|---|
| `printed_page` | Erkannte gedruckte Zahl, beispielsweise `12` oder `iv`; sonst `null`. |
| `printed_page_status` | `recognized`: erkannt; `unknown`: fehlt; `ambiguous`: mehrere Werte; `uncertain`: unsicher. |
| `pdf_position` / `pdf_positions` | Eindeutige Positionen innerhalb der PDF-Datei, ab eins. |
| `page_details` | Gedruckter Wert, Status und PDF-Position je betroffener Seite. |
| `pdf_page_label` | Zusatzangabe des PDF-Programms; ersetzt niemals die gedruckte Zahl. |

Nenne zuerst die gedruckte Seite und zusätzlich die PDF-Position.
Beispiel: „Gedruckte Seite iv, PDF-Position 6“.
Kennzeichne fehlende oder unklare Zahlen ausdrücklich. Erfinde keinen Wert aus dem Programm-Seitenlabel.
Auch ohne `--screenshot` prüft `cite` die Randzahlen im Original.

Textdateien und JSONL nennen mit `line_basis=source_file` echte Dateizeilen ab eins.
Andere Texte nennen mit `line_basis=extracted_block` Zeilen im ausgelesenen Textblock.
EPUB verwendet `part`, `chapter`, `ordinal`, `element` und gegebenenfalls `element_id` für Kapitel und Elementposition.
`converted_document_page` bezeichnet die Seite einer Office-Umwandlung.
Zeichenpositionen beginnen bei null; die Endposition gehört nicht mehr zum Zitat.
Bei `--next-ref` nennt `next_position` Zeichen und Zeilen des zweiten Textblocks.
JSON- und Tabellenzitate können normalisierte Darstellungen sein. Beachte `quote_basis` und alle Warnungen.

## Tabellen, Archive und Aufnahmen

Bei XLSX und XLSM nennt `sheet` das Blatt und `cells` die Originalzelladressen.
`normalized_spreadsheet` bezeichnet gespeicherte Werte mit Formatanweisungen, keine sichtbare Tabellenansicht.
Beachte Datumsbasis, Prozentformat und Hinweise auf fehlende oder veraltete Formelwerte.

Bei Archiven bezeichnet `archive_chain` die vollständige Folge der enthaltenen Dateien.
`archive_member_pdf_page` ist eine Original-PDF-Position innerhalb dieses Mitglieds, keine umgewandelte Office-Seite.
Präsentationen nennen `slide` und `shape` für Folie und Textelement.
Für diese neuen Quellenarten erzeugt das Werkzeug keine Originalseitenbilder.

Bei Aufnahmen nennen `start_seconds`, `end_seconds` und `stream` den Zeitbereich und die Spur.
`automatic_transcript` bezeichnet automatisch erkannte, ungeprüfte Sprache.
`timestamp_basis` unterscheidet eingebettete Zeiten, geschätzte Modellzeiten und ganze Audiofenster.
Eine bestätigte Dateiprüfsumme beweist weder den erkannten Wortlaut noch sekundengenaue Aussagegrenzen.
Prüfe entscheidende Aussagen am angegebenen Originalabschnitt. Kennzeichne fehlende Hörprüfung ausdrücklich.
Sichtbare Folien und sonstige Videobilder bleiben ungeprüft; Untertitel und Sprache belegen deren Inhalt nicht vollständig.

## Zitat über zwei Seiten

Mit `--next-ref ZWEITE_REFERENZ` ergänzt du die nächste gespeicherte Passage derselben PDF-Fassung.
Beide Passagen müssen auf benachbarten Seiten stehen. Verbinde ihren gewünschten Wortlaut mit einem Zeilenumbruch.
Der Wortlaut muss beide Passagen umfassen. Gespeicherte inhaltliche Zwischenblöcke dürfen nicht übersprungen werden.
Die Ausgabe kennzeichnet zwei getrennte Originalausschnitte. Sie beweist keine lückenlose Originalfolge oder vollständige Textextraktion.
Eindeutige Seitenzahlen und wiederholte Kopf- oder Fußzeilen dürfen zwischen den Passagen stehen.
Gespeicherte mehrseitige Fundstellen funktionieren ohne `--next-ref`, sofern ihre Position eindeutig bleibt.

## Originalausschnitte als Bild

Über die lokale Werkzeugschnittstelle setzt der Assistent `screenshot=true`.
Die Antwort liefert das geprüfte Bild direkt als Bildinhalt, zusätzlich zu den Textangaben.
Die empfangende Anwendung muss Bildantworten darstellen können. Eine Textausgabe allein bestätigt keine sichtbare Darstellung.
Prüfe das tatsächlich empfangene Bild auf Lesbarkeit und vollständigen Zusammenhang.

`--screenshot` speichert nur die ausgewählte Passage mit kleinem Rand.
Bei zwei Seiten stehen beide Ausschnitte untereinander. Graue Beschriftungsbereiche liegen außerhalb der Originalpixel.
`screenshot.crops` nennt je Ausschnitt PDF-Position, gedruckte Zahl, Status und Rechteck.
Die Rechtecke verwenden PDF-Punkte mit Ursprung links oben auf der sichtbaren Seite.
`image_box` bezeichnet die Originalpixel im fertigen Bild.
Die Bildangaben nennen außerdem Auflösung, Abmessungen und Prüfsummen für Bild und Originaldatei.

Die Antwort enthält `screenshot.relative_path`, beispielsweise `citations/…png`.
Im üblichen Aufbau liegt die Datei unter `$UKE_DATA_DIR/knowledge`, ergänzt um diesen relativen Pfad.
`screenshot.path` bezeichnet den Pfad innerhalb des laufenden Dienstes.
Verlinke das tatsächlich gespeicherte Bild. Bilder bleiben lokal erhalten und werden nicht automatisch gelöscht.
Sichere benötigte Bilder gesondert.

## Ursprungsquelle bevorzugen

`source.reference.url` nennt eine ausdrücklich zugeordnete Ursprungsadresse aus lokalen Begleitmetadaten.
Suchtreffer und Quellenübersichten verwenden dafür `source_reference.url`.
Verlinke diese Adresse unmittelbar an der belegten Aussage.
`kind=file` bezeichnet eine Dateiadresse. `kind=landing_page` bezeichnet die zugehörige Ursprungsseite.
`version_verified=false` bedeutet: Die aktuelle Online-Fassung wurde nicht geprüft.
Die Zitatprüfung gilt weiterhin für die lokale Originaldatei mit der angegebenen Inhaltsprüfsumme.
Fehlt eine eindeutige Adresse, bleibt `label` als Dateiangabe erhalten.
Ergänze bei gleichen Bezeichnungen den vollständigen Originalpfad.
Die Auflösung lädt keine Internetseiten und verlangt kein erneutes Einlesen der Dokumente.

Begleitdateien dürfen beliebige Namen mit der Endung `.json` verwenden, beispielsweise `metadata.json` oder `object.json`.
Sie werden im Dateiordner und dessen unmittelbarem Elternordner gesucht.
Alle Pfade müssen innerhalb des eingelesenen Dokumentordners liegen.
Lokale Zuordnungen verwenden `local_path`, `path`, `filename` oder `file_name`, relativ zur Begleitdatei.
Datensätze können unter `records`, `files` oder `attachments` stehen.
Dateiadressen verwenden `file_url` oder `download_url`.
Ursprungsseiten verwenden `object_url`, `landing_page_url`, `source_url`, `original_url`, `canonical_url` oder `links.self.href`.
Ein `url`-Feld innerhalb einer ausdrücklich zugeordneten Anlage bezeichnet deren Dateiadresse.
Widersprüchliche Angaben führen zum Dateiverweis. Unbekannte Exportformen werden nicht erraten.

Beispiel einer `metadata.json` neben einem Unterordner `files`:

```json
{
  "object_url": "https://example.org/dokumente/17",
  "files": [{"local_path": "files/bericht.pdf"}]
}
```

Dieses Beispiel ordnet der lokalen Datei eine Ursprungsseite zu, keine online geprüfte Dateifassung.
Pro Begleitdatei werden höchstens 256 KiB gelesen. Symbolischen Verknüpfungen wird nicht gefolgt.
Die Suche prüft insgesamt höchstens 16 JSON-Dateien und höchstens 256 Verzeichniseinträge je Ordner.
Bei überschrittenen Grenzen bleibt die eindeutige Dateiangabe erhalten.
Innerhalb einer Anfrage werden Zuordnungen wiederverwendet. Die nächste Anfrage liest die Begleitdaten erneut.
Pro Anfrage werden höchstens vier MiB Begleitdaten gelesen und 128 Zwischenergebnisse gespeichert.
Bei Zitaten erklärt `source.reference.reason` den Dateiverweis:
`missing` bedeutet fehlende Zuordnung, `ambiguous` widersprüchliche Angaben, `limit` erreichte Grenze und `invalid_metadata` ungültige Begleitdaten.

## Grenzen

Gedruckte Zahlen werden konservativ aus klaren Randmustern erkannt, etwa `Seite 12`, `- 12 -` oder `iv`.
Ungewöhnliche Typografie kann unbekannt bleiben. Konkurrierende Werte bleiben mehrdeutig.
Bildtexterkennung kann bei Scans und fehlendem Originaltext Koordinaten liefern.
Ihre Konfidenzwerte sind Heuristiken, keine Wahrheitswahrscheinlichkeiten. Unsichere Koordinaten führen zu einem Fehler.
Bildtexterkennung bestätigt den sichtbaren Wortlaut und prüft beide Seitenränder auch ohne Bildwunsch.
OCR-Teilwortzitate werden abgelehnt; wähle ganze Wörter.
Bei überschrittenen Bildgrenzen bleiben reine Textbelege mit unbekannter gedruckter Zahl und ausdrücklichem Grund verfügbar.
Prüfe wichtige Zitate zusätzlich am Originalbild.

Bildbelege gedrehter Seiten führen derzeit zu einem ausdrücklichen Fehler. Einseitige Textzitate bleiben mit unbekannter gedruckter Zahl verfügbar.
Beschnittene Seiten benötigen eindeutig umrechenbare Koordinaten.
Mehrdeutiger Wortlaut und normalisierte Tabellen erhalten keinen scheinbar exakten Bildbeleg.
EPUB und andere Formate erhalten keine erfundenen Originalseitenbilder.
Ein Auftrag verarbeitet höchstens zwei benachbarte PDF-Seiten innerhalb von 60 Sekunden und zwei GiB Prozessspeicher.
Raster und fertige Bilder bleiben auf 16 Millionen Bildpunkte begrenzt. Bilddateien dürfen höchstens 16 Millionen Bytes enthalten.
Große Raster und zusammengesetzte Bilder werden vor ihrer Erzeugung geprüft.
