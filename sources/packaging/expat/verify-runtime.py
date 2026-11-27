import ctypes,json,pathlib
root=pathlib.Path(__file__).resolve().parent/"runtime-libs"
results={}
for kind,expected in [("original",b"expat_2.9.0"),("candidate",b"expat_2.10.0")]:
 for name in ["libexpat.so.1","libexpatw.so.1"]:
  lib=ctypes.CDLL(str(next((root/kind).rglob(name))))
  lib.XML_ExpatVersion.restype=ctypes.c_char_p
  assert lib.XML_ExpatVersion()==expected
  lib.XML_ParserCreate.argtypes=[ctypes.c_void_p];lib.XML_ParserCreate.restype=ctypes.c_void_p
  lib.XML_SetElementHandler.argtypes=[ctypes.c_void_p,ctypes.c_void_p,ctypes.c_void_p]
  lib.XML_Parse.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_int,ctypes.c_int];lib.XML_Parse.restype=ctypes.c_int
  lib.XML_ParserFree.argtypes=[ctypes.c_void_p]
  names=[]
  @ctypes.CFUNCTYPE(None,ctypes.c_void_p,ctypes.c_void_p,ctypes.c_void_p)
  def start(user,pointer,attrs):
   if name=="libexpat.so.1":names.append(ctypes.string_at(pointer).decode())
   else:
    p=ctypes.cast(pointer,ctypes.POINTER(ctypes.c_ushort)); chars=[];i=0
    while p[i]:chars.append(chr(p[i]));i+=1
    names.append("".join(chars))
  parser=lib.XML_ParserCreate(None)
  assert parser
  try:
   lib.XML_SetElementHandler(parser,start,None)
   xml="<grüße><kind>Text</kind></grüße>".encode()
   assert lib.XML_Parse(parser,xml,len(xml),1)==1
   assert names==["grüße","kind"],names
  finally:lib.XML_ParserFree(parser)
  results[kind+"/"+name]={"version":expected.decode(),"names":names,"passed":True}
print(json.dumps(results,ensure_ascii=False,indent=2))

