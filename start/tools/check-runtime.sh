#!/bin/sh
# Prüft den tatsächlichen Linux-Kern vor Modelldownload und Dokumentverarbeitung.
set -eu
runtime=${UKE_RUNTIME:-docker}
set --
tmpfs_owner="uid=$(id -u),gid=$(id -g)"
case "${runtime##*/}" in podman) set -- --userns=keep-id --read-only-tmpfs=false; tmpfs_owner=U ;; esac
"$runtime" run --rm --name "${UKE_CONTAINER:-uke-engine}-preflight-$$" \
 --cpus 1 --memory 256m --memory-swap 256m --pids-limit 64 \
 -e "UKE_TRUSTED_INPUTS=${UKE_TRUSTED_INPUTS-0}" \
 --network none --read-only --cap-drop ALL \
 --security-opt no-new-privileges --user "$(id -u):$(id -g)" "$@" \
 --tmpfs "/run/uke:rw,nosuid,nodev,size=16m,mode=700,$tmpfs_owner" \
 --entrypoint python "${UKE_IMAGE:-ghcr.io/deltatree/data2oracle-runtime:main}" -c '
import platform
import subprocess
import sys
import tempfile
from pathlib import Path
from uke.sandbox import version, required_version
probe = """
import socket
import sys
from pathlib import Path
from uke.sandbox import enforce
root = Path(sys.argv[1])
enforce(root / "source.txt", root / "scratch", Path("/data/models"))
assert (root / "source.txt").read_text() == "Erlaubt."
(root / "scratch" / "allowed.txt").write_text("Erlaubt.")
try:
    (root / "secret.txt").read_text()
except PermissionError:
    pass
else:
    raise RuntimeError("Unerlaubte Datei bleibt lesbar.")
with socket.socket() as stream:
    try:
        stream.bind(("127.0.0.1", 0))
    except PermissionError:
        pass
    else:
        raise RuntimeError("Netzwerkverbot ist nicht wirksam.")
"""
try:
    abi = version()
    with tempfile.TemporaryDirectory(prefix="uke-preflight-") as directory:
        root = Path(directory)
        (root / "source.txt").write_text("Erlaubt.")
        (root / "secret.txt").write_text("Gesperrt.")
        (root / "scratch").mkdir()
        result = subprocess.run([sys.executable, "-c", probe, directory], capture_output=True, text=True, timeout=15)
        if result.returncode:
            raise RuntimeError("Schutzregeln nicht wirksam: " + result.stderr.strip())
except (RuntimeError, OSError, subprocess.TimeoutExpired) as error:
    raise SystemExit("Vorprüfung fehlgeschlagen: " + str(error) + ". Linux-VM aktualisieren; die Schutzfunktion darf nicht abgeschaltet werden.")
if required_version()==7:
    print("Eigene vertrauenswürdige Dateien: verfügbare Schutzregeln aktiv. Unter Version 10 fehlt zusätzlicher UDP-Schutz; unter Version 9 der Schutz lokaler Socketpfade. Der Container muss ohne Netzwerk laufen.")
print(f"Vorprüfung erfolgreich: Linux {platform.release()}, {platform.machine()}, Landlock ABI {abi}; Dateischutz und TCP-Netzsperre wirksam.")
'
