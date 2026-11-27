#!/bin/sh
# Baut die vorhandenen Sicherheitskorrekturen nativ aus geprüften Quellen.
set -eu
test "$(dpkg --print-architecture)" = arm64
export DEBIAN_FRONTEND=noninteractive
export DEB_BUILD_OPTIONS=parallel=2
export SOURCE_DATE_EPOCH=1795219200
mkdir -p /out/debs /out/wheels /out/extensions /work
trap 'status=$?; if [ "$status" -ne 0 ]; then for log in /out/*.log; do if [ -f "$log" ]; then printf "\n%s\n" "$log"; tail -40 "$log"; fi; done; fi' 0
python /sources/arm64/verify-inputs.py
rm -f /etc/apt/sources.list.d/debian.sources
printf '%s\n' \
 'deb [check-valid-until=no] https://snapshot.debian.org/archive/debian/20261121T000000Z trixie main' \
 'deb [check-valid-until=no] https://snapshot.debian.org/archive/debian-security/20261121T000000Z trixie-security main' > /etc/apt/sources.list
apt-get update
apt-get install -y --no-install-recommends build-essential dpkg-dev debhelper \
 dh-python liblzma-dev libpython3-all-dev pkg-config python3-all-dev python3-setuptools rename zlib1g-dev \
 gtk-doc-tools libcurl4-openssl-dev libglib2.0-dev libicu-dev libtool libxml2-dev libxslt1-dev libyajl-dev \
 docbook-to-man docbook2x libraptor2-dev libexpat1-dev

for name in libxml2 raptor expat; do
 mkdir -p "/work/$name/reference" "/work/$name/original" "/work/$name/candidate"
done
cd /work/libxml2/reference
apt-get download libxml2 libxml2-dev
cd /work/raptor/reference
apt-get download libraptor2-0 libraptor2-dev
cd /work/expat/reference
apt-get download libexpat1 libexpat1-dev
for name in libxml2 raptor expat; do
 for package in /work/"$name"/reference/*.deb; do dpkg-deb -x "$package" "/work/$name/original"; done
done

cd /work/libxml2
dpkg-source -x /sources/libxml2/sources/libxml2_2.12.7+dfsg+really2.9.14-2.1+deb13u3.dsc build
cd build
patch -p1 < /sources/libxml2/patches/libxml2-uke-backport.patch
cp /sources/libxml2/changelog debian/changelog
dpkg-buildpackage -us -uc -b -j2 > /out/libxml2-build.log 2>&1
python /sources/libxml2/testdata.py /work/libxml2/build /work/libxml2/upstream > /out/libxml2-testdata.json
make -j2 check > /out/libxml2-upstream-tests.log 2>&1
for package in ../libxml2_*.deb ../libxml2-dev_*.deb; do dpkg-deb -x "$package" /work/libxml2/candidate; done
python /sources/arm64/verify-library.py libxml2 libxml2.so.2 libxml2 xml2
dpkg -i ../libxml2_*.deb ../libxml2-dev_*.deb
cp ../libxml2_*_arm64.deb /out/debs/

cd /work/raptor
dpkg-source -x /sources/raptor/sources/raptor2_2.0.16-6.dsc build
cd build
patch -p1 < /sources/raptor/patches/raptor2-uke-backport.patch
patch -p1 < /sources/raptor/patches/raptor-generated-sync.patch
cp /sources/raptor/changelog debian/changelog
dpkg-buildpackage -us -uc -b -j2 > /out/raptor-build.log 2>&1
for package in ../libraptor2-0_*.deb ../libraptor2-dev_*.deb; do dpkg-deb -x "$package" /work/raptor/candidate; done
python /sources/arm64/verify-library.py raptor libraptor2.so.0 raptor2 raptor2
dpkg -i ../libraptor2-0_*.deb ../libraptor2-dev_*.deb
cp ../libraptor2-0_*_arm64.deb /out/debs/

cd /work/expat
dpkg-source -x /sources/expat/sources/expat_2.10.0-1.dsc build
cd build
python - <<'PY'
from pathlib import Path
p = Path('debian/changelog')
p.write_text('expat (2.10.0-1+uke1) trixie; urgency=high\n\n  * Korrigierte Herstellerfassung mit Trixie-Werkzeugkette gebaut.\n\n -- UKE Build <build@uke.invalid>  Sun, 22 Nov 2026 00:00:00 +0000\n\n' + p.read_text())
PY
dpkg-buildpackage -us -uc -b -j2 > /out/expat-build.log 2>&1
make -j2 -C build check > /out/expat-upstream-tests.log 2>&1
for package in ../libexpat1_*.deb ../libexpat1-dev_*.deb; do dpkg-deb -x "$package" /work/expat/candidate; done
dpkg -i ../libexpat1_*.deb ../libexpat1-dev_*.deb
cp ../libexpat1_*_arm64.deb /out/debs/
mkdir -p /work/expat/proofs /work/expat/runtime-libs
cp ../libexpat1-dev_*.deb /work/expat/proofs/
cp /sources/expat/verify-abi.py /sources/expat/verify-runtime.py /work/expat/
ln -s /work/expat/original /work/expat/runtime-libs/original
ln -s /work/expat/candidate /work/expat/runtime-libs/candidate
python /work/expat/verify-abi.py > /out/expat-abi.json
python /work/expat/verify-runtime.py > /out/expat-runtime.json

python -m pip install --require-hashes -r /sources/lxml/build-requirements.lock
mkdir -p /work/lxml /work/pyexpat
tar -xf /sources/lxml/lxml-6.1.3.tar.gz -C /work/lxml
cd /work/lxml/lxml-6.1.3
python -m pip wheel --no-deps --no-build-isolation --wheel-dir /out/wheels . > /out/lxml-build.log 2>&1
python -m pip install --no-index --no-deps /out/wheels/*.whl
python -c 'from lxml import etree; assert etree.LIBXML_VERSION == (2, 9, 14); assert etree.LIBXML_COMPILED_VERSION == (2, 9, 14)'
python - <<'PY'
import hashlib
import json
from pathlib import Path, PurePosixPath
import zipfile
wheel = next(Path('/out/wheels').glob('lxml-*.whl'))
extensions = {}
with zipfile.ZipFile(wheel) as archive:
    for name in archive.namelist():
        if not name.endswith('.so'):
            continue
        parts = PurePosixPath(name).parts
        assert parts[0] == 'lxml' and '..' not in parts, name
        data = archive.read(name)
        target = Path('src').joinpath(*parts)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        extensions[name] = hashlib.sha256(data).hexdigest()
assert extensions, 'Keine lxml-Erweiterungen im Paket.'
Path('/out/lxml-tested-extensions.json').write_text(json.dumps({'wheel': wheel.name, 'sha256': hashlib.sha256(wheel.read_bytes()).hexdigest(), 'tested_extensions': extensions}, indent=2) + '\n')
PY
PYTHONPATH=src python -c 'from lxml import etree; assert etree.__file__.startswith("/work/lxml/lxml-6.1.3/src/")'
python test.py > /out/lxml-upstream-tests.log 2>&1

tar -xf /sources/pyexpat/Python-3.12.16.tar.xz -C /work/pyexpat
cd /work/pyexpat/Python-3.12.16
./configure --enable-shared --with-system-expat --enable-loadable-sqlite-extensions > /out/pyexpat-configure.log 2>&1
extension=$(python -c 'import sysconfig; print("pyexpat" + sysconfig.get_config_var("EXT_SUFFIX"))')
make -j2 "Modules/$extension" > /out/pyexpat-build.log 2>&1
cp "Modules/$extension" /out/extensions/
PYTHONPATH=/out/extensions python -c 'import pyexpat; assert pyexpat.EXPAT_VERSION == "expat_2.10.0"; assert pyexpat.__file__.startswith("/out/extensions/")'
PYTHONPATH=/out/extensions:/work/pyexpat/Python-3.12.16/Lib python -m test -v test_pyexpat test_xml_etree test_xml_etree_c test_minidom test_sax test_xml_dom_minicompat > /out/pyexpat-upstream-tests.log 2>&1
dpkg-query -W > /out/build-packages.lock
cd /out
find debs wheels extensions -type f -exec sha256sum {} \; > outputs.sha256
printf '%s\n' 'Alle nativen ARM-Quellbauten und Prüfungen bestanden.'
