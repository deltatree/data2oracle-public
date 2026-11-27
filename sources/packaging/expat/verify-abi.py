import pathlib,tempfile,subprocess,json,difflib
p=pathlib.Path(__file__).resolve().parent
with tempfile.TemporaryDirectory() as temp:
 root=pathlib.Path(temp)
 for kind,deb in [("original",next((p/"reference").glob("libexpat1_*.deb"))),("candidate",next(p.glob("libexpat1_*.deb"))),("olddev",next((p/"reference").glob("libexpat1-dev_*.deb"))),("newdev",next((p/"proofs").glob("libexpat1-dev_*.deb")))]:
  subprocess.run(["dpkg-deb","-x",str(deb),str(root/kind)],check=True)
 results={}
 for lib in ["libexpat.so.1","libexpatw.so.1"]:
  symbols={};sonames={}
  for kind in ["original","candidate"]:
   path=next((root/kind).rglob(lib))
   output=subprocess.check_output(["nm","-D","--defined-only",str(path)],text=True)
   symbols[kind]={tuple(line.split()[1:]) for line in output.splitlines()}
   sonames[kind]=[line.split("[")[1].split("]")[0] for line in subprocess.check_output(["readelf","-d",str(path)],text=True).splitlines() if "SONAME" in line]
  removed=symbols["original"]-symbols["candidate"]
  assert not removed,(lib,removed)
  assert sonames["original"]==sonames["candidate"],sonames
  results[lib]={"soname":sonames["candidate"],"old_symbols":len(symbols["original"]),"new_symbols":len(symbols["candidate"]),"removed":[],"added":sorted(symbols["candidate"]-symbols["original"])}
 headers=[]
 for name in ["expat.h","expat_external.h"]:
  old=next((root/"olddev").rglob(name)).read_text().splitlines(True)
  new=next((root/"newdev").rglob(name)).read_text().splitlines(True)
  headers.extend(difflib.unified_diff(old,new,fromfile="original/"+name,tofile="candidate/"+name))
 (p/"headers.diff").write_text("".join(headers))
 (p/"abi-proof.json").write_text(json.dumps(results,indent=2))
 print(json.dumps(results,indent=2))

