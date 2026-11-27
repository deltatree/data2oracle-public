"""Vergleicht die ARM-Bibliothek mit ihrem unveränderten Debian-Paket."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys

name, library, include, link = sys.argv[1:]
root = Path('/work') / name
old, new = root / 'original', root / 'candidate'
multiarch = subprocess.check_output(['dpkg-architecture', '-qDEB_HOST_MULTIARCH'], text=True).strip()
relative = Path('usr/lib') / multiarch

def run(args):
    return subprocess.check_output(args, text=True)

def symbols(directory):
    return sorted(' '.join(line.split()[-2:]) for line in run(['nm', '-D', '--defined-only', str(directory / relative / library)]).splitlines())

def soname(directory):
    return next(line.split('[')[1].split(']')[0] for line in run(['readelf', '-d', str(directory / relative / library)]).splitlines() if 'SONAME' in line)

def headers(directory):
    base = directory / 'usr/include'
    return {str(p.relative_to(base)): hashlib.sha256(p.read_bytes()).hexdigest() for p in base.rglob('*.h')}

assert headers(old) == headers(new), 'Öffentliche Header unterscheiden sich.'
assert symbols(old) == symbols(new), 'Exportierte Symbole unterscheiden sich.'
assert soname(old) == soname(new) == library, 'Bibliotheksname unterscheidet sich.'
program = root / 'regression'
subprocess.run(['cc', f'/sources/{name}/regression.c', '-I' + str(old / 'usr/include' / include), '-L' + str(old / relative), '-l' + link, '-o', str(program)], check=True)
results = {}
for label, directory, expected in [('original', old, 1), ('candidate', new, 0)]:
    result = subprocess.run([str(program)], env=dict(os.environ, LD_LIBRARY_PATH=str(directory / relative)), text=True, capture_output=True)
    assert result.returncode == expected, (label, result.returncode, result.stdout, result.stderr)
    results[label] = {'exit': result.returncode, 'stdout': result.stdout.strip()}
Path(f'/out/{name}-verification.json').write_text(json.dumps({'architecture': multiarch, 'headers_equal': True, 'symbols_equal': True, 'soname': library, 'regression': results}, indent=2) + '\n')
print(json.dumps(results))
