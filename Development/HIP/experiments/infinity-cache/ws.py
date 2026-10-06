import gzip,json,sys,collections
for tag in ['900','1080']:
    jobs=[json.loads(l[4:]) for l in gzip.open(f'/home/lmxxf/work/ai-theorys-study/wechat/assets/297/Development/results/kernel-map-900-20260930/record-{tag}-jobs.txt.gz','rt') if l.startswith('JOB ')]
    bufs={}  # ptr->max bytes
    wbytes=0
    for j in jobs:
        for a in j['args']:
            if a['type']=='ptr' and not a['file'] and a['bytes']>=1<<16:
                if a['value'] in (0,): continue
                bufs[a['value']]=max(bufs.get(a['value'],0),a['bytes'])
            elif a['type']=='ptr' and a['file']: wbytes+=a['bytes']
    tot=sum(bufs.values())
    # per-dispatch touched activation bytes; LRU stack distance per buffer access (whole-buffer granularity)
    lru=collections.OrderedDict(); dists=[]; per=[]
    fam=collections.defaultdict(lambda:[0,0,0])
    for j in jobs:
        acts=[(a['value'],a['bytes']) for a in j['args'] if a['type']=='ptr' and not a['file'] and a['value'] and a['bytes']>=1<<16]
        per.append(sum(b for _,b in acts))
        for p,b in dict(acts).items():
            if p in lru:
                d=0
                for q in reversed(lru):
                    if q==p: break
                    d+=lru[q]
                hit = d+b<=64<<20
                dists.append((j['symbol'],b,d,hit))
                f=j['symbol'].split('_')[0]; fam[f][0]+=b; fam[f][1]+=b*hit
                lru.move_to_end(p)
            else: dists.append((j['symbol'],b,None,False))
            lru[p]=b
    nb=sum(b for _,b,_,_ in dists); hb=sum(b for _,b,_,h in dists if h)
    print(tag,'dispatches',len(jobs),'distinct act buffers',len(bufs),'footprint MB %.1f'%(tot/2**20),'max per-dispatch touched MB %.1f'%(max(per)/2**20),
          'weight-arg MB %.1f'%(wbytes/2**20),'act access MB %.0f'%(nb/2**20),'reuse<=64MB frac %.2f'%(hb/nb))
    big=sorted(bufs.values(),reverse=True)[:8]; print(' biggest MB',[round(b/2**20,1) for b in big])
    for f,(a,h,_) in sorted(fam.items(),key=lambda x:-x[1][0])[:10]: print('  %-10s access %6.0fMB  reuse-in-64MB %.2f'%(f,a/2**20,h/a if a else 0))
