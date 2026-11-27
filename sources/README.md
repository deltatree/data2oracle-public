# Fremdquellen und Neubau

Dieses Archiv enthält ausgewählte Fremdquellen, Paketkorrekturen, Lizenztexte und zugehörige Neubauskripte.
Es enthält keine Entwicklungshistorie und keine privaten Betriebsprotokolle.
`CONTENTS.sha256` erfasst jede ausgelieferte Datei mit SHA-256.

## Inhalt

- `packaging/raptor`: Raptor 2.0.16, Debian-Paketierung und beide UKE-Patches.
- `packaging/libxml2`: libxml2 2.9.14 mit Debian-Paketierung und UKE-Patch.
- `packaging/expat`: Expat 2.10.0 und Debian-Paketierung.
- `packaging/lxml`: lxml 6.1.3 samt Lizenztexten und Bauabhängigkeiten.
- `packaging/pyexpat`: Python 3.12.16 einschließlich Quellen und Lizenz.
- `packaging/arm64`: native ARM-Bauskripte für diese Komponenten.
- `leanrdf-build`: getrennte Neubauskripte mit festgelegten Herstellerquellen.
- `requirements.lock` und `requirements.arm64.lock`: Python-Versionen und Paketprüfsummen je Architektur.

Die Komponentenmanifeste enthalten nur Prüfsummen tatsächlich mitgelieferter Quellen und Bauanweisungen.
Die ursprünglichen privaten Prüfprotokolle sind nicht Bestandteil dieser Ausgabe.
Die ergänzte Datei `CONTENTS.sha256` bindet auch die gekürzten Manifeste.

## Fremdquellen prüfen

Führe im entpackten Ordner aus:

```sh
sha256sum -c CONTENTS.sha256
```

Die Debian-Dateien unter `sources/` enthalten Herstellerarchive, Debian-Änderungen und signierte Quellenbeschreibungen.
Die zusätzlichen Korrekturen stehen separat unter `patches/`.
Die Copyright-Dateien nennen Urheber, Lizenzen und Herkunft.

## Komponenten neu bauen

Baue ausschließlich in getrennten Linux-Baucontainern, niemals im laufenden UKE-Dienst.
Die Skripte verändern die Paketquellen und installieren Bauabhängigkeiten im jeweiligen Container.
Sie benötigen Netzwerkzugriff; ein vollständiger Offline-Neubau wird nicht zugesagt.
Bauabhängigkeiten stehen in `debian/control` nach dem Entpacken der Debian-Quellen.

Für Raptor und libxml2 benötigst du Debian Trixie, `dpkg-dev`, `patch` und die jeweiligen Paket-Bauabhängigkeiten.
Führe danach im zugehörigen Komponentenordner `sh rebuild.sh` aus.
Das Skript nennt abschließend seinen temporären Bauordner.
libxml2 lädt zusätzliche Herstellerprüfdaten; deren Prüfsumme wird vor Verwendung geprüft.

Die Expat-, lxml- und pyexpat-Skripte verwenden dieses Basisimage:

```text
python:3.12.16-slim-trixie@sha256:05a994d2344eb364cc186910f4fc8786a38215f39f00d0acc25bff33a08f4177
```

Binde jeweils eine beschreibbare Kopie des Komponentenordners unter `/work` ein.
Starte darin `sh /work/rebuild.sh`.
Die Skripte benötigen Rootrechte ausschließlich im getrennten Baucontainer.

Baue zuerst Expat und libxml2.
Für lxml benötigt `/patches` das gebaute libxml2-Laufzeitpaket und unter `/patches/proofs` dessen Entwicklerpaket.
Für pyexpat benötigt `/expat` das gebaute Expat-Laufzeitpaket und unter `/expat/proofs` dessen Entwicklerpaket.
Diese zusätzlichen Pfade werden aus deinen Bauausgaben befüllt und lesend eingebunden.
Die pyexpat-Einzelbauanweisung ist für x86_64 festgelegt.
Für ARM64 verwende den gemeinsamen nativen Bauablauf.

Der native ARM64-Bau benötigt das genannte Python-Basisimage auf einem ARM64-Linux-Host.
Binde den vollständigen Ordner `packaging` lesend unter `/sources` ein.
Stelle getrennte beschreibbare Ordner unter `/out` und `/work` bereit.
Starte darin `sh /sources/arm64/build.sh`.
Der Ablauf prüft zuerst Quellhashes und baut anschließend alle fünf Komponenten.
Er führt außerdem Hersteller- und Schnittstellenprüfungen aus.
Ein Quellbau bestätigt keine Betriebsfähigkeit des fertigen UKE-Pakets auf einem bestimmten Mac.

Die einzelnen Skripte begrenzen den Container nicht selbst.
Setze beim Aufruf eigene CPU-, Speicher- und Prozessgrenzen.
Die Archive lassen sich reproduzierbar packen; ein bitidentischer Komponenten-Neubau ist damit nicht nachgewiesen.

## LeanRDF, Lean und LeanElpi

Die Skripte laden ausdrücklich festgelegte öffentliche Herstellerstände:

- LeanRDF: https://github.com/Volland/rdf-lean/tree/3ccc0eeaace0e6642fa79fbd5cb9cab929101921
- Lean 4.35.0: https://github.com/leanprover/lean4/releases/tag/v4.35.0
- LeanElpi ist über LeanRDFs `elpi/lake-manifest.json` gebunden.

`leanrdf-build/build.sh` prüft das Lean-Archiv und übernimmt die Herstellerlizenzen.
Führe im Ordner `leanrdf-build` auf einem getrennten Linux-Bauhost aus:

```sh
sh run.sh
docker wait uke-leanrdf-build
```

Fahre ausschließlich bei Ausgabe `0` fort:

```sh
docker commit uke-leanrdf-build uke-leanrdf-builder:0.5.0
docker run --rm --name uke-leanrdf-package --cpus=2 --memory=4g --memory-swap=4g --network none \
  -v "$PWD:/work" uke-leanrdf-builder:0.5.0 sh /work/package.sh
sh run-tests.sh
```

Ein vorhandener gleichnamiger Container verhindert einen Doppelstart.
Die erzeugten Binärdateien liegen unter `artifacts/bin`, die Lizenztexte unter `artifacts/licenses`.
Der Aufbau erzeugt seine neuen Prüfberichte ausschließlich in diesem Bauordner.

## Weitere unveränderte Komponenten

Die genauen installierten Versionen stehen im Anwendungspaket unter `/opt/python-lock.txt` und `/opt/debian-packages.lock`.
`/opt/wheels-manifest.json` nennt die ausgelieferten Python-Pakete und ihre Prüfsummen.
Python-Herstellerquellen stehen auf https://pypi.org/ unter der jeweiligen festgelegten Paketversion bereit.
Die Debian-Quellen stammen aus https://snapshot.debian.org/archive/debian/20261121T000000Z/ und dem entsprechenden Debian-Sicherheitsarchiv.
Die Pakete nennen ihre Herkunft und Lizenz unter `/usr/share/doc/<paket>/copyright`.
PDFium-Lizenzen stehen beim installierten pypdfium2-Paket unter dessen `.dist-info/licenses`-Ordner.
Modelltexte und Herstellerrevisionen stehen im Anwendungspaket unter `/usr/share/licenses/uke-models` und nach Vorbereitung unter `models/licenses`.

Beachte die Lizenzbedingungen der einzelnen Komponenten bei einer Weitergabe.
Die MIT-Lizenz eigener Dateien ersetzt weder fremde Bedingungen noch erforderliche Quellenhinweise.
