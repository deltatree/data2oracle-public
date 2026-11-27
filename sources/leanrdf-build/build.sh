#!/bin/sh
set -eu
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends ca-certificates curl git zstd build-essential libgmp-dev
mkdir -p /work/downloads /work/artifacts/bin /work/artifacts/lib /work/artifacts/licenses /work/evidence
cd /work
case "$(uname -m)" in
 x86_64) lean_dir=lean-4.35.0-linux; lean_sha=7289597a44543246c9227b8cae501767e095ce17f6d448b95fc4a8dc97268f6d ;;
 aarch64) lean_dir=lean-4.35.0-linux_aarch64; lean_sha=c8f0f8a3920e839718b1343e6781fd80a3e9b1024fbcd7078eb30f54e806b028 ;;
 *) printf '%s\n' 'Nicht unterstützte Rechnerarchitektur.' >&2; exit 2 ;;
esac
if [ ! -f "downloads/$lean_dir.tar.zst" ]; then
 curl --fail --location --retry 3 -o "downloads/$lean_dir.tar.zst" "https://github.com/leanprover/lean4/releases/download/v4.35.0/$lean_dir.tar.zst"
fi
printf '%s  %s\n' "$lean_sha" "downloads/$lean_dir.tar.zst" | sha256sum -c -
if [ ! -d "$lean_dir" ]; then tar --zstd -xf "downloads/$lean_dir.tar.zst"; fi
export PATH=/work/$lean_dir/bin:$PATH
export LEAN_NUM_THREADS=2
lean --version
if [ ! -d rdf-lean/.git ]; then
 git clone https://github.com/Volland/rdf-lean.git rdf-lean
fi
cd /work/rdf-lean
git checkout --detach 3ccc0eeaace0e6642fa79fbd5cb9cab929101921
git rev-parse HEAD > /work/evidence/source-commit.txt
cp LICENSE-MIT /work/artifacts/licenses/LeanRDF-MIT
cp LICENSE-APACHE /work/artifacts/licenses/LeanRDF-APACHE
cp "/work/$lean_dir/LICENSE" /work/artifacts/licenses/Lean4-LICENSE
(cd check && lake build leanrdf-check)
cp check/.lake/build/bin/leanrdf-check /work/artifacts/bin/
(cd shacl && lake build leanrdf-shacl)
cp shacl/.lake/build/bin/leanrdf-shacl /work/artifacts/bin/
(cd elpi && lake build leanrdf-demo)
cp elpi/.lake/build/bin/leanrdf-demo /work/artifacts/bin/
cp elpi/.lake/packages/lean-elpi/LICENSE /work/artifacts/licenses/LeanElpi-LICENSE
find /work/artifacts/bin -type f -exec ldd {} \; > /work/evidence/ldd.txt
find /work/artifacts/bin -type f -exec sha256sum {} \; > /work/evidence/binaries.sha256
printf 'ERFOLG\n' > /work/evidence/build-result.txt
