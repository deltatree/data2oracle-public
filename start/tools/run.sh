#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
runtime=${UKE_RUNTIME:-docker}
data_dir=${UKE_DATA_DIR:-$project_dir}
case "$data_dir" in *:*) printf '%s\n' 'UKE_DATA_DIR darf keinen Doppelpunkt enthalten.' >&2; exit 2 ;; esac
case "$data_dir" in /*) ;; *) printf '%s\n' 'UKE_DATA_DIR muss ein absoluter Pfad sein.' >&2; exit 2 ;; esac
for manifest in manifest.json extra-manifest.json; do
 [ -f "$data_dir/models/$manifest" ] || { printf '%s\n' 'Modelle fehlen. Zuerst sh tools/prepare-models.sh ausführen.' >&2; exit 2; }
done
sh "$project_dir/tools/check-runtime.sh"
umask 077
mkdir -p "$data_dir/knowledge" "$data_dir/documents"
set --
tmpfs_owner="uid=$(id -u),gid=$(id -g)"
case "${runtime##*/}" in podman) set -- --userns=keep-id --read-only-tmpfs=false; tmpfs_owner=U ;; esac
exec "$runtime" run -d --name "${UKE_CONTAINER:-uke-engine}" --restart unless-stopped \
 -e "UKE_TRUSTED_INPUTS=${UKE_TRUSTED_INPUTS-0}" \
 --network none --cpus 4 --memory 8g --memory-swap 8g --pids-limit 256 \
 --stop-timeout "${UKE_STOP_TIMEOUT:-150}" \
 --read-only --cap-drop ALL --security-opt no-new-privileges \
 --tmpfs "/run/uke:rw,nosuid,nodev,size=2g,mode=700,$tmpfs_owner" \
 --user "$(id -u):$(id -g)" "$@" \
 -v "$data_dir/documents:/data/documents:ro" \
 -v "$data_dir/knowledge:/data/knowledge" \
 -v "$data_dir/models:/data/models:ro" \
 "${UKE_IMAGE:-ghcr.io/deltatree/data2oracle-runtime:main}"
