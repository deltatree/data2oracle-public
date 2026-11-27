import sys
from pathlib import Path,PurePosixPath
import hashlib,json,tarfile,urllib.request
base="https://download.gnome.org/sources/libxml2/2.9/"
name="libxml2-2.9.14.tar.xz"
checks=urllib.request.urlopen(base+"libxml2-2.9.14.sha256sum",timeout=45).read().decode()
expected=next(line.split()[0] for line in checks.splitlines() if line.split()[-1].lstrip("*")==name)
data=urllib.request.urlopen(base+name,timeout=60).read()
actual=hashlib.sha256(data).hexdigest()
assert actual==expected,(expected,actual)
archive=Path(sys.argv[2])/name
archive.parent.mkdir(parents=True,exist_ok=True)
archive.write_bytes(data)
copied=0
with tarfile.open(archive) as tar:
    for member in tar:
        parts=PurePosixPath(member.name).parts
        if len(parts)<3 or parts[0]!="libxml2-2.9.14" or parts[1] not in {"test","result"}:continue
        assert ".." not in parts
        if not member.isfile():continue
        assert member.size<16000000
        target=Path(sys.argv[1]).joinpath(*parts[1:])
        if target.exists():continue
        target.parent.mkdir(parents=True,exist_ok=True)
        target.write_bytes(tar.extractfile(member).read())
        copied+=1
report={"url":base+name,"checksum_url":base+"libxml2-2.9.14.sha256sum","sha256":actual,"test_files_added":copied,"scope":"Nur separater Prüfbaum; bestehende Debian-Regressionen erhalten; keine Produktinstallation."}
(Path(sys.argv[2])/"xml-testdata-manifest.json").write_text(json.dumps(report,indent=2))
print(json.dumps(report))
