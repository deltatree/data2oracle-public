#!/bin/sh
# Benötigt einen getrennten Trixie-Builder mit den Paket-Bauabhängigkeiten.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
build=$(mktemp -d)
dpkg-source -x "$root/sources/libxml2_2.12.7+dfsg+really2.9.14-2.1+deb13u3.dsc" "$build/libxml2"
cd "$build/libxml2"
patch -p1 < "$root/patches/libxml2-uke-backport.patch"
cp "$root/changelog" debian/changelog
dpkg-buildpackage -us -uc -b -j2
python3 "$root/testdata.py" "$build/libxml2" "$build/upstream"
make -j2 check
printf '%s\n' "$build"
