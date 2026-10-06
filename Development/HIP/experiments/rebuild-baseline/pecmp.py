#!/usr/bin/env python3
"""pecmp.py a.dll b.dll : compare PE sections (.text/.rdata/.data/...), print size + same/diff per section, and
count differing bytes in .text. Timestamps / debug dirs make whole-file hashes useless for MinGW builds."""
import struct, sys
def secs(p):
    d=open(p,'rb').read(); pe=struct.unpack_from('<I',d,0x3c)[0]; n=struct.unpack_from('<H',d,pe+6)[0]; opt=struct.unpack_from('<H',d,pe+20)[0]
    o={}
    for i in range(n):
        b=pe+24+opt+40*i; name=d[b:b+8].rstrip(b'\0').decode(errors='replace'); vs,va,rs,rp=struct.unpack_from('<IIII',d,b+8)
        o[name]=d[rp:rp+min(vs,rs) if vs else rs]
    return o
a,b=secs(sys.argv[1]),secs(sys.argv[2]); bad=0
for k in sorted(set(a)|set(b)):
    x,y=a.get(k),b.get(k)
    if x==y: print(f'SAME {k} {len(x)}'); continue
    bad+=1; nd=sum(1 for i,j in zip(x or b'',y or b'') if i!=j) if x and y else -1
    print(f'DIFF {k} {len(x) if x else None} vs {len(y) if y else None} bytes-differ={nd}')
sys.exit(1 if bad else 0)
