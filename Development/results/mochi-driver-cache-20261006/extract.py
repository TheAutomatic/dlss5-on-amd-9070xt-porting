"""Offline extract complete ELF objects from a locked Vulkan cache; no device API."""
from pathlib import Path
import argparse,struct,hashlib,json
p=argparse.ArgumentParser();p.add_argument('cache',type=Path);p.add_argument('output',type=Path);a=p.parse_args();b=a.cache.read_bytes();a.output.mkdir(exist_ok=True,parents=True);rows=[]
for n,o in enumerate(i for i in range(len(b)) if b.startswith(b'\x7fELF',i)):
 z=b[o:];assert z[4:6]==bytes([2,1]);shoff=struct.unpack_from('<Q',z,40)[0];esz,num=struct.unpack_from('<HH',z,58);size=shoff+esz*num
 for i in range(num):
  q=shoff+i*esz;t=struct.unpack_from('<I',z,q+4)[0];off,sz=struct.unpack_from('<QQ',z,q+24)
  if t!=8:size=max(size,off+sz)
 assert size<=len(z);raw=z[:size];name=f'cache-{n:02}.elf';(a.output/name).write_bytes(raw);rows.append({'file':name,'cache_offset':o,'bytes':size,'sha256':hashlib.sha256(raw).hexdigest()})
(a.output/'extraction.json').write_text(json.dumps({'cache_sha256':hashlib.sha256(b).hexdigest(),'cache_bytes':len(b),'objects':rows},indent=2)+'\n')
