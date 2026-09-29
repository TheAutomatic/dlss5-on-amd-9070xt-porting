from pathlib import Path
import struct,msgpack,json
out={}
for p in Path('/tmp/kernel-map/flat-A').glob('*.hsaco'):
 d=p.read_bytes();shoff=struct.unpack_from('<Q',d,40)[0];sz,num=struct.unpack_from('<HH',d,58)
 for i in range(num):
  h=struct.unpack_from('<IIQQQQIIQQ',d,shoff+i*sz)
  if h[1]!=7:continue
  b=d[h[4]:h[4]+h[5]];off=0
  while off+12<=len(b):
   ns,ds,typ=struct.unpack_from('<III',b,off);off+=12;name=b[off:off+ns];off+=(ns+3)&~3;desc=b[off:off+ds];off+=(ds+3)&~3
   if name.rstrip(b'\0')==b'AMDGPU' and typ==32:
    m=msgpack.unpackb(desc,raw=False)
    for k in m['amdhsa.kernels']:out[p.name+':'+k['.name']]={'module_file':'flat-A/'+p.name,**k}
Path('/tmp/kernel-map/ours-metadata.json').write_text(json.dumps(out,indent=2));print(len(out),'kernel metadata')
