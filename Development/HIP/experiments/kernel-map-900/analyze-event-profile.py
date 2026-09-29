import sys,statistics as st,collections,csv
def load(p):
    d=collections.defaultdict(list);names={}
    for l in open(p):
        if not l.startswith('KEV,'):continue
        _,f,i,mod,k,g,t,ms=l.strip().split(',');f=int(f);i=int(i)
        if f<30:continue
        d[i].append(float(ms));names[i]=(mod,k,int(g),int(t))
    return {i:(names[i],st.median(v)*1000,len(v)) for i,v in d.items()}
out=sys.argv[1]
for h in (900,1080):
    m=load(f'logs/prof-{h}/run8.log')
    with open(f'{out}/dispatch-{h}.csv','w') as f:
        w=csv.writer(f);w.writerow(['index','module','kernel','groups','threads','median_us','samples'])
        for i in sorted(m):(mod,k,g,t),us,n=m[i];w.writerow([i,mod,k,g,t,f'{us:.3f}',n])
    agg=collections.OrderedDict()
    for i in sorted(m):
        (mod,k,g,t),us,n=m[i];key=(mod,k)
        a=agg.setdefault(key,[0,0.0,set()]);a[0]+=1;a[1]+=us;a[2].add(f'{g}x{t}')
    tot=sum(a[1] for a in agg.values())
    rows=sorted(agg.items(),key=lambda x:-x[1][1])
    with open(f'{out}/kernels-{h}.csv','w') as f:
        w=csv.writer(f);w.writerow(['rank','module','kernel','calls','total_us','per_call_us','share_pct','shapes'])
        for r,((mod,k),(c,us,sh)) in enumerate(rows,1):w.writerow([r,mod,k,c,f'{us:.1f}',f'{us/c:.2f}',f'{100*us/tot:.2f}',' '.join(sorted(sh))])
    print(h,'entries',len(m),'sum_us',round(tot,1))
