#!/bin/sh
set -eu
root_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
docker run --rm --name uke-leanrdf-tests --cpus=2 --memory=4g --memory-swap=4g \
 --network none --read-only --cap-drop ALL --security-opt no-new-privileges \
 --pids-limit 64 --user 1000:1000 --tmpfs /tmp:rw,nosuid,nodev,size=64m \
 -v "$root_dir/artifacts:/work/artifacts:ro" \
 -v "$root_dir/rdf-lean/examples:/work/rdf-lean/examples:ro" \
 -v "$root_dir/evidence/tests:/work/evidence/tests:rw" \
 -v "$root_dir/test.sh:/work/test.sh:ro" \
 debian:bookworm-20251117-slim@sha256:b4aa902587c2e61ce789849cb54c332b0400fe27b1ee33af4669e1f7e7c3e22f \
 sh /work/test.sh
