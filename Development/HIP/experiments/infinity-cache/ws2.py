import gzip,json,collections
for tag in ['900','1080']:
    jobs=[json.loads(l[4:]) for l in gzip.open(f'/home/lmxxf/work/ai-theorys-study/wechat/assets/297/Development/results/kernel-map-900-20260930/record-{tag}-jobs.txt.gz','rt') if l.startswith('JOB ')]
    fams=collections.OrderedDict()
    for j in jobs:
        f=j['symbol'].split('_')[0]
        acts={a['value']:a['bytes'] for a in j['args'] if a['type']=='ptr' and not a['file'] and a['value'] and a['bytes']>=1<<16}
        d=fams.setdefault(f,{'n':0,'bufs':{},'maxd':0})
        d['n']+=1; d['maxd']=max(d['maxd'],sum(acts.values()))
        for p,b in acts.items(): d['bufs'][p]=max(d['bufs'].get(p,0),b)
    print(tag)
    for f,d in fams.items(): print('  %-10s disp %3d  distinct-buf-MB %6.1f  max-per-dispatch-MB %6.1f'%(f,d['n'],sum(d['bufs'].values())/2**20,d['maxd']/2**20))
