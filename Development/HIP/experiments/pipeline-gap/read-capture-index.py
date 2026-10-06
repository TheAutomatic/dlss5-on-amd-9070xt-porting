"""Offline RDF3 index/metadata inventory. Does not infer dispatch names or sample timing."""
from pathlib import Path
import struct,json,argparse,hashlib
p=argparse.ArgumentParser();p.add_argument('trace',type=Path);p.add_argument('output',type=Path);a=p.parse_args();b=a.trace.read_bytes();magic,ver,res,off,size=struct.unpack_from('<8sIIQQ',b);assert magic==b'AMD_RDF ' and ver==3 and res==0 and size%64==0 and off+size<=len(b);rows=[];meta={}
for q in range(off,off+size,64):
 name,comp,v,ho,hs,do,ds,raw=struct.unpack_from('<16sIIQQQQQ',b,q);name=name.rstrip(b'\0').decode();assert ho+hs<=len(b) and do+ds<=len(b);rows.append({'name':name,'version':v,'compression':comp,'header_bytes':hs,'data_bytes':ds,'uncompressed_bytes':raw})
 if name in ('TraceConfig','ApiInfo') and comp==0:
  d=b[do:do+ds].rstrip(b'\0')
  try:meta[name]=json.loads(d)
  except (ValueError,UnicodeDecodeError):meta[name]={'header_hex':b[ho:ho+hs].hex(),'data_hex':d.hex()}
a.output.write_text(json.dumps({'trace_sha256':hashlib.sha256(b).hexdigest(),'trace_bytes':len(b),'chunks':rows,'metadata':meta,'mapping_status':'inventory only: dispatch function sequence requires actual event/marker decoder and labelled API-reference sequence; no fabricated names'},indent=2)+'\n')
print(json.dumps({'chunk_names':[r['name']for r in rows],'metadata':meta},indent=2))
