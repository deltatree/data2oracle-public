#!/bin/sh
# Baut nur im eigenen Arbeitsverzeichnis; benötigt Debian-Bauwerkzeuge.
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
build=$(mktemp -d)
dpkg-source -x "$root/sources/raptor2_2.0.16-6.dsc" "$build/raptor"
cd "$build/raptor"
patch -p1 < "$root/patches/raptor2-uke-backport.patch"
patch -p1 < "$root/patches/raptor-generated-sync.patch"
cp "$root/changelog" debian/changelog
dpkg-buildpackage -us -uc -b -j2
printf '%s\n' "$build"
