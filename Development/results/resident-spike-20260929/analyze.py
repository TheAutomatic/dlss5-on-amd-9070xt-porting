import csv,statistics as s
for n in ['A1','B1','A2','B2']:
    w=[float(r['wall_ms']) for r in csv.DictReader(open(n+'.csv'))]
    idx=list(range(len(w)))
    keep=[(i,x) for i,x in enumerate(w) if i>=200]
    v=sorted(x for _,x in keep);N=len(v)
    p=lambda q:v[min(N-1,int(q*N))]
    med=s.median(v);thr=med+3
    sp=[i for i,x in keep if x>thr]
    m60=[i for i in sp if i%60 in(0,59,1)]
    mx=max(keep,key=lambda t:t[1])
    # mean of frames with i%60==0 vs rest
    on=[x for i,x in keep if i%60==0];off=[x for i,x in keep if i%60!=0]
    print(f"{n} n={N} avg={s.mean(v):.3f} p50={p(.5):.3f} p99={p(.99):.3f} max={mx[1]:.2f}@{mx[0]} (%60={mx[0]%60}) spikes>{thr:.1f}={len(sp)} near60={len(m60)} mean@i%60==0={s.mean(on):.3f} rest={s.mean(off):.3f}")
