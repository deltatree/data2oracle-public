#!/bin/sh
set -eu
# Auf einem Linux-Bauhost ausführen. Ein bestehender Container verhindert einen Doppelstart.
root_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
docker run -d --name uke-leanrdf-build --cpus=2 --memory=4g --memory-swap=4g \
  -v "$root_dir:/work" \
  debian:bookworm-20251117-slim@sha256:b4aa902587c2e61ce789849cb54c332b0400fe27b1ee33af4669e1f7e7c3e22f \
  sh /work/build.sh
