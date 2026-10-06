import sys,collections,re
sys.path.insert(0,'.')
from cls import fam
def run(path,regions):
    L=open(path).read().splitlines()
    tot=collections.Counter();per={}
    for (a,b,mult,name) in regions:
        c=collections.Counter()
        for l in L[a-1:b]:
            s=l.strip()
            if not s or s.startswith(('/',';','.')) or s.endswith(':'): continue
            o=s.split()[0]; f=fam(o); c[f]+=mult; c['_n']+=mult
            if f.startswith('V:'): c['VALU']+=mult
        per[name]=c; tot+=c
    print(path); 
    for n,c in per.items(): print(f"  {n:14s} VALU {c['VALU']:5d} WMMA {c['WMMA']:4d} SALU {c['SALU']:4d} wait {c['wait']:4d} LDS {c['LDS']:4d} MEM {c['MEM']:4d} | "+' '.join(f"{k[2:]}={v}" for k,v in sorted(c.items()) if k.startswith('V:')))
    print('  TOTAL',{k:v for k,v in sorted(tot.items())})
run('c32_wave1_prefix_b8d.s',[(1,125,1,'entry'),(126,533,4,'qt-input'),(534,594,32,'ht-loop'),(595,897,4,'qt-qkv'),(898,918,1,'mid'),(919,1404,4,'attn'),(1405,1439,1,'tail-setup'),(1440,1522,16,'tail-main'),(1523,2408,1,'tail-down')])
run('c32_wave1_post_b8.s',[(1,111,1,'entry'),(112,538,4,'qt-input'),(539,599,32,'ht-loop'),(600,902,4,'qt-qkv'),(903,923,1,'mid'),(924,1409,4,'attn'),(1410,1459,1,'tail-setup'),(1460,1843,2,'rgb-head')])
