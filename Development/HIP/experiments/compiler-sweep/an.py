import sys,collections,statistics as st
L=[l.split() for l in open(sys.argv[1]) if l.startswith('SPAN')]
seq=[]
for l in L:
    r,h,c=l[1].split('-',2); seq.append((r,h,c,float(l[-1].split('=')[1])))
res=collections.defaultdict(list)
for key in sorted(set((r,h) for r,h,_,_ in seq)):
    s=[x for x in seq if (x[0],x[1])==key]
    b=[(i,x[3]) for i,x in enumerate(s) if x[2].startswith('base')]
    for i,x in enumerate(s):
        lo=max([p for p in b if p[0]<=i] or [b[0]],key=lambda p:p[0]); hi=min([p for p in b if p[0]>=i] or [b[-1]],key=lambda p:p[0])
        ref=lo[1] if hi[0]==lo[0] else lo[1]+(hi[1]-lo[1])*(i-lo[0])/(hi[0]-lo[0])
        res[(x[1],x[2])].append((x[3]-ref)*1000)
for h in ('h900','h1080'):
    print(h)
    for (hh,c),v in res.items():
        if hh==h: print('  %-20s %s med %+.0f'%(c,' '.join('%+5.0f'%x for x in v),st.median(v)))
