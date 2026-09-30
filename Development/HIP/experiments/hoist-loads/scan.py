import re,json,collections,sys
R='/home/lmxxf/work/ai-theorys-study/wechat/assets/297/Development/results/kernel-map-900-20260930/'
jobs=json.load(open(R+'ours900-jobs.json'))
us={}
for l in open(R+'ours-900-dispatch.csv').readlines()[1:]:
  p=l.strip().split(',');us[p[0]]=float(p[5]) if p[5] else 0
agg=collections.defaultdict(lambda:[0,0.0,None,0])
for j in jobs:
  k=(j['module_file'].split('/')[-1].replace('.hsaco',''),j['symbol']);a=agg[k];a[0]+=1;a[1]+=us.get(j['id'],0);a[2]=j['grid'][0]*j['grid'][1]*j['grid'][2];a[3]=j['block'][0]
cache={}
def funcs(m):
  if m in cache:return cache[m]
  cur=None;out={}
  for l in open(f'{sys.argv[1]}/{m}.s'):
    mm=re.match(r'^[0-9a-f]+ <(.+)>:',l)
    if mm: cur=mm.group(1);out[cur]=[];continue
    if cur is not None: out[cur].append(l)
  cache[m]=out;return out
rows=[]
for (m,s),(n,u,g,b) in agg.items():
  try:L=funcs(m).get(s)
  except FileNotFoundError: L=None
  if not L: rows.append((u,m,s,n,'NOSYM'));continue
  infl=0;serial=0;w0=0;loads=0;runs=[];run=0;prev_serial=False
  for l in L:
    if re.search(r'\b(global_load|buffer_load)',l): infl+=1;loads+=1
    elif 's_wait_loadcnt 0x0' in l and 'dscnt' not in l.split('s_wait_loadcnt')[0]:
      w0+=1
      if infl<=2: serial+=1;run+=1
      else:
        if run>=3: runs.append(run)
        run=0
      infl=0
    elif 's_wait_loadcnt' in l:
      k=int(l.split('0x')[1].split()[0],16);infl=min(infl,k)
  if run>=3:runs.append(run)
  rows.append((u,m,s,n,f'len {len(L)} loads {loads} w0 {w0} serial {serial} runs>=3 {sorted(runs,reverse=True)[:8]} grid {g}'))
for r in sorted(rows,reverse=True): print(f'{r[0]:7.1f}us x{r[3]:2d} {r[1]}:{r[2]}  {r[4]}')
