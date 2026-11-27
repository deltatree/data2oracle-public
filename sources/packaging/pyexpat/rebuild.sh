#!/bin/sh
# Baut nur Pythons XML-Erweiterung gegen die korrigierte Systembibliothek.
set -eu
cd /work
rm -f /etc/apt/sources.list.d/debian.sources
printf '%s\n' 'deb [check-valid-until=no] https://snapshot.debian.org/archive/debian/20261121T000000Z trixie main' > /etc/apt/sources.list
apt-get update
apt-get install -y --no-install-recommends build-essential pkg-config libexpat1-dev
dpkg -i /expat/libexpat1_*.deb /expat/proofs/libexpat1-dev_*.deb
python - <<'PY'
from pathlib import Path
import urllib.request,hashlib,tarfile
p=Path("Python-3.12.16.tar.xz")
if not p.exists():urllib.request.urlretrieve("https://www.python.org/ftp/python/3.12.16/Python-3.12.16.tar.xz",p)
assert hashlib.sha256(p.read_bytes()).hexdigest()=="b5796915dc45ff745cfb4e990a7e7c93d6f546328a102ce31448d69ebc37575c"
with tarfile.open(p) as t:t.extractall("/work/build",filter="data")
PY
cd /work/build/Python-3.12.16
./configure --enable-shared --with-system-expat --enable-loadable-sqlite-extensions
make -j2 Modules/pyexpat.cpython-312-x86_64-linux-gnu.so
mkdir -p /work/artifacts
cp Modules/pyexpat.cpython-312-x86_64-linux-gnu.so /work/artifacts/
cp LICENSE /work/LICENSE
cd /work
PYTHONPATH=/work/artifacts python -c 'import pyexpat; assert pyexpat.EXPAT_VERSION=="expat_2.10.0"; print(pyexpat.__file__,pyexpat.EXPAT_VERSION)' > runtime.txt
PYTHONPATH=/work/artifacts:/work/build/Python-3.12.16/Lib python -m test -v test_pyexpat test_xml_etree test_xml_etree_c test_minidom test_sax test_xml_dom_minicompat > /work/upstream-tests.log 2>&1
