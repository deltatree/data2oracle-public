#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
runtime=${UKE_RUNTIME:-docker}
data_dir=${UKE_DATA_DIR:-$project_dir}
case "$data_dir" in *:*) printf '%s\n' 'UKE_DATA_DIR darf keinen Doppelpunkt enthalten.' >&2; exit 2 ;; esac
case "$data_dir" in /*) ;; *) printf '%s\n' 'UKE_DATA_DIR muss ein absoluter Pfad sein.' >&2; exit 2 ;; esac
ca_bundle=${UKE_CA_BUNDLE:-}
if [ -n "$ca_bundle" ]; then
 case "$ca_bundle" in /*) ;; *) printf '%s\n' 'UKE_CA_BUNDLE muss ein absoluter Pfad sein.' >&2; exit 2 ;; esac
 case "$ca_bundle" in *:*) printf '%s\n' 'UKE_CA_BUNDLE darf keinen Doppelpunkt enthalten.' >&2; exit 2 ;; esac
 [ -f "$ca_bundle" ] && [ -r "$ca_bundle" ] || { printf '%s\n' 'Zertifikatsdatei nicht lesbar: UKE_CA_BUNDLE prüfen.' >&2; exit 2; }
fi
sh "$project_dir/tools/check-runtime.sh"
umask 077
mkdir -p "$data_dir/models" "$data_dir/documents" "$data_dir/knowledge"
set --
tmpfs_owner="uid=$(id -u),gid=$(id -g)"
case "${runtime##*/}" in podman) set -- --userns=keep-id --read-only-tmpfs=false; tmpfs_owner=U ;; esac
if [ -n "$ca_bundle" ]; then
 set -- "$@" -v "$ca_bundle:/run/uke-extra-ca.pem:ro" -e UKE_CA_CERT=/run/uke-extra-ca.pem
fi
exec "$runtime" run --rm --name "${UKE_CONTAINER:-uke-engine}-models" \
 --cpus 4 --memory 8g --memory-swap 8g --pids-limit 256 \
 --read-only --cap-drop ALL --security-opt no-new-privileges \
 --user "$(id -u):$(id -g)" "$@" \
 --tmpfs "/run/uke:rw,nosuid,nodev,size=2g,mode=700,$tmpfs_owner" \
 -v "$data_dir/models:/work/models" \
 --entrypoint python "${UKE_IMAGE:-ghcr.io/deltatree/data2oracle-runtime:main}" -c '
import os
import runpy
import ssl
import sys
import urllib.error
import urllib.request
ca=os.environ.get("UKE_CA_CERT")
if ca:
    context=ssl.create_default_context()
    try:
        context.load_verify_locations(cafile=ca)
    except (OSError,ssl.SSLError) as error:
        raise SystemExit("Zusätzliche Zertifikatsdatei ist ungültig oder nicht lesbar.") from error
    urllib.request.install_opener(urllib.request.build_opener(urllib.request.HTTPSHandler(context=context)))
try:
    sys.argv=sys.argv[1:]
    runpy.run_path(sys.argv[0],run_name="__main__")
except urllib.error.URLError as error:
    if isinstance(error.reason,ssl.SSLCertVerificationError):
        raise SystemExit("Modellserver-Zertifikat nicht vertrauenswürdig. Im Firmennetz UKE_CA_BUNDLE auf die freigegebene Zertifikatsdatei setzen.") from None
    raise
' /opt/uke-provision/provision-models-locked.py
