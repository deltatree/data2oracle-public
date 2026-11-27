#!/bin/sh
# Baut die korrigierte Expat-Version mit der bestehenden Trixie-Werkzeugkette.
set -eu
cd /work
if [ -f /work/build/expat-2.10.0/build-stamp ]; then
make -j2 -C /work/build/expat-2.10.0/build check
exit 0
fi
rm -f /etc/apt/sources.list.d/debian.sources
printf '%s\n' 'deb [check-valid-until=no] https://snapshot.debian.org/archive/debian/20261121T000000Z trixie main' 'deb [check-valid-until=no] https://snapshot.debian.org/archive/debian-security/20261121T000000Z trixie-security main' 'deb-src [check-valid-until=no] https://snapshot.debian.org/archive/debian/20261121T000000Z sid main' > /etc/apt/sources.list
apt-get update
apt-get install -y --no-install-recommends dpkg-dev ca-certificates
apt-get build-dep -y --no-install-recommends expat=2.10.0-1
mkdir -p sources reference build
cd /work/sources
apt-get source --download-only expat=2.10.0-1
cd /work/reference
apt-get download libexpat1 libexpat1-dev
cd /work/build
dpkg-source -x /work/sources/expat_2.10.0-1.dsc
cd expat-2.10.0
python3 - <<'PY'
from pathlib import Path
p=Path("debian/changelog")
p.write_text("expat (2.10.0-1+uke1) trixie; urgency=high\n\n  * Korrigierte Herstellerfassung mit Trixie-Werkzeugkette gebaut.\n\n -- UKE Build <build@uke.invalid>  Sun, 22 Nov 2026 00:00:00 +0000\n\n"+p.read_text())
PY
DEB_BUILD_OPTIONS=parallel=2 dpkg-buildpackage -us -uc -b
cp ../libexpat1_*.deb /work/
cp debian/copyright /work/copyright
dpkg-query -W > /work/build-packages.lock
make -j2 -C /work/build/expat-2.10.0/build check
