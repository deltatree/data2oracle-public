#!/bin/sh
# Baut lxml gegen die bereits korrigierte Systembibliothek.
set -eu
cd /work
rm -f /etc/apt/sources.list.d/debian.sources
printf '%s\n' 'deb [check-valid-until=no] https://snapshot.debian.org/archive/debian/20261121T000000Z trixie main' 'deb [check-valid-until=no] https://snapshot.debian.org/archive/debian-security/20261121T000000Z trixie-security main' > /etc/apt/sources.list
apt-get update
apt-get install -y --no-install-recommends build-essential libxml2-dev libxslt1-dev zlib1g-dev
dpkg -i /patches/libxml2_*.deb /patches/proofs/libxml2-dev_*.deb
python -m pip install --require-hashes -r /work/build-requirements.lock
python - <<'PY'
import hashlib,urllib.request,pathlib,tarfile
p=pathlib.Path("lxml-6.1.3.tar.gz")
if not p.exists(): urllib.request.urlretrieve("https://files.pythonhosted.org/packages/23/ad/28ecd7cb894d172f3c9c80a075eeeb2017ac62e3632cee05a5f9493547eb/lxml-6.1.3.tar.gz",p)
assert hashlib.sha256(p.read_bytes()).hexdigest()=="45222d94ddd511536f3b2f7d9deae3b2339b4ce0f075f1ca25703b07cad9dd21"
with tarfile.open(p) as t:t.extractall("/work/build",filter="data")
PY
cd /work/build/lxml-6.1.3
SOURCE_DATE_EPOCH=1795219200 python -m pip wheel --no-deps --no-build-isolation --wheel-dir /work/wheels .
python -m pip install --no-index --no-deps /work/wheels/*.whl
python -c 'from lxml import etree; import json; print(json.dumps({"runtime":etree.LIBXML_VERSION,"compiled":etree.LIBXML_COMPILED_VERSION,"extension":etree.__file__}))' > /work/runtime.json
python setup.py build_ext -i
python test.py > /work/upstream-tests.log 2>&1
