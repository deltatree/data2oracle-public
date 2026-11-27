"""Prüft die vorhandenen Quellen und Korrekturen vor dem nativen ARM-Bau."""
import hashlib
import json
from pathlib import Path

root = Path('/sources')
checked = {}
for name in ('raptor', 'libxml2', 'expat'):
    directory = root / name
    manifest = json.loads((directory / 'manifest.json').read_text())
    hashes = manifest.get('sha256', manifest.get('files'))
    paths = [p for folder in ('sources', 'patches') for p in (directory / folder).glob('*') if p.is_file()]
    if (directory / 'changelog').exists():
        paths.append(directory / 'changelog')
    for path in paths:
        relative = str(path.relative_to(directory))
        actual = hashlib.sha256(path.read_bytes()).hexdigest()
        assert actual == hashes[relative], (name, relative)
        checked[f'{name}/{relative}'] = actual
for name, expected in {
    'lxml/lxml-6.1.3.tar.gz': '45222d94ddd511536f3b2f7d9deae3b2339b4ce0f075f1ca25703b07cad9dd21',
    'pyexpat/Python-3.12.16.tar.xz': 'b5796915dc45ff745cfb4e990a7e7c93d6f546328a102ce31448d69ebc37575c',
}.items():
    actual = hashlib.sha256((root / name).read_bytes()).hexdigest()
    assert actual == expected, name
    checked[name] = actual
Path('/out/input-sha256.json').write_text(json.dumps(checked, indent=2, sort_keys=True) + '\n')
print(f'{len(checked)} Quelldateien geprüft.')
