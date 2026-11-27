#!/bin/sh
# Stdio bleibt offen; ein Terminal würde Protokollnachrichten verändern.
set -eu
exec "${UKE_RUNTIME:-docker}" exec -i "${UKE_CONTAINER:-uke-engine}" uke mcp
