#!/bin/sh
set -eu
cd /work
for binary in artifacts/bin/*; do strip --strip-debug "$binary"; done
cp /usr/share/doc/libc6/copyright artifacts/licenses/glibc-copyright
cp /work/rdf-lean/elpi/lake-manifest.json evidence/lean-elpi.lock.json
find artifacts/bin -type f -exec ldd {} \; > evidence/ldd.txt
find artifacts/bin -type f -exec sha256sum {} \; > evidence/binaries.sha256
find artifacts/licenses -type f -exec sha256sum {} \; > evidence/licenses.sha256
mkdir -p evidence/tests
chown 1000:1000 evidence/tests
cat evidence/ldd.txt
ls -lh artifacts/bin
