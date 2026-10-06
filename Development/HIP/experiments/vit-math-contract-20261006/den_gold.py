"""Small independent positive-half 640-key denominator gold, exact half-add order."""
from pathlib import Path
import argparse,json,hashlib
import numpy as np
ap=argparse.ArgumentParser();ap.add_argument('output',type=Path);a=ap.parse_args();a.output.mkdir(parents=True,exist_ok=True)
code=np.arange(0x1c20,0x3e90+1,16,dtype='<u2');prob=code.view('<f2');k=np.arange(640)
rows=np.array([np.full(640,prob[0]),np.full(640,prob[-1]),np.where(k%2,prob[0],prob[-1]),prob[(k*137+19)%len(prob)],prob[((639-k)*137+19)%len(prob)],np.where(k%8==0,prob[-1],prob[0]),prob[(k*37+(k//64)*53)%len(prob)],prob[k%len(prob)]],dtype='<f2')
def h(x):return np.float16(x)
def add(x,y):return h(float(x)+float(y))
checks=[];gold=[];chunks=[]
for row in rows:
    den=h(0);partial=[]
    for begin in range(0,640,64):
        acc=[]
        for j in range(8):
            v=add(row[begin+j],row[begin+j+8])
            for t in [16,32,48]:v=add(v,add(row[begin+t+j],row[begin+t+j+8]))
            acc.append(v)
        even=add(add(add(acc[0],acc[2]),acc[4]),acc[6]);odd=add(add(add(acc[1],acc[3]),acc[5]),acc[7]);den=add(den,add(even,odd));partial.append(den)
    seq=h(0)
    for p in row:seq=add(seq,p)
    checks.append({'tree_half':float(den),'sequential_half':float(seq),'different_from_sequential':bool(den.view('<u2')!=seq.view('<u2'))});gold.append(den);chunks.append(partial)
rows.tofile(a.output/'probability-8x640.f16');np.asarray(gold,dtype='<f2').tofile(a.output/'denominator-8.f16');np.asarray(chunks,dtype='<f2').tofile(a.output/'denominator-8x10-prefix.f16')
report={'rows':8,'tokens':640,'full_chunks':10,'probability_code_domain':'1c20..3e90 step16, all positive normal half','reference':'exact binary64 additions followed by half-RNE, operations sequenced from natural key identities, not implementation shuffle layout','checks':checks,'files':{p.name:{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in a.output.glob('*.f16')}};(a.output/'den-gold.json').write_text(json.dumps(report,indent=2));print(json.dumps(checks,indent=2))
