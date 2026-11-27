#!/bin/sh
set -eu
runtime=${UKE_RUNTIME:-docker}
if ! command -v "$runtime" >/dev/null 2>&1; then
    printf '%s\n' "Die Container-Laufzeit '$runtime' ist nicht verfügbar. Prüfe UKE_RUNTIME und den Programmpfad dieser Sitzung." >&2
    exit 127
fi
exec "$runtime" exec "${UKE_CONTAINER:-uke-engine}" uke research "$@"
