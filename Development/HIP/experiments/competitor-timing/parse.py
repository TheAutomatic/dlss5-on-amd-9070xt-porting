import re,glob,json,collections,sys
d=sys.argv[1]
res={};bad=[]
for f in glob.glob(d+'/*.log'):
    t=open(f,encoding='utf-8',errors='ignore').read()
    id=f.split('/')[-1][:-4]
    m=re.search(r'RESULT,[^,]+,([0-9.]+)',t)
    chk=re.findall(r'CHECK[^\n]*',t)
    okc=all((re.search(r'guards=0,',c) and 'invalid=0' in c) for c in chk) if chk else False
    if m and okc: res[id]=float(m.group(1))
    else: bad.append(id)
sets=collections.defaultdict(list)
for id,v in res.items():
    sets[id.split('-')[0]].append(v)
fam=collections.defaultdict(float)
jobs={}
for q in ['ref900','fast900','ref1088','fast1088','v050ref900']:
    for j in json.load(open(f'dj-{q}.json')): jobs[j['id']]=j
for id,v in res.items():
    j=jobs[id]; skip=str(j['position']) in ('block42','block43','block46')
    fam[(id.split('-')[0],j['family'],skip)]+=v
out={}
for s,v in sorted(sets.items()):
    sk=sum(res[i] for i in res if i.startswith(s+'-') and str(jobs[i]['position']) in ('block42','block43','block46'))
    out[s]={'n':len(v),'sum_us':round(sum(v),1),'skip424346_us':round(sk,1),'sum_minus_skip_us':round(sum(v)-sk,1)}
print(json.dumps(out,indent=1)); print('bad',len(bad),sorted(bad)[:20])
json.dump({'sets':out,'bad':bad,'per_job':res,'family':{f'{a}|{b}|{"skipblk" if c else ""}':round(v,1) for (a,b,c),v in fam.items()}},open('daniel-jobbench.json','w'),indent=1)
