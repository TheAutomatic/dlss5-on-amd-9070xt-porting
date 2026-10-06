import csv,collections,re,subprocess,math
K='/home/lmxxf/work/ai-theorys-study/wechat/assets/297/Development/results/kernel-map-v3-20260930/'
disp={}
for t in ('900','1080'):
  for r in csv.DictReader(open(K+f'ours-{t}-dispatch.csv')): disp[r['id']]=r
meta={}
for m in ['c512-m32-deep','c512-m32-mh','deep_fast-packed','multihead-fast-padded-wave-packed','vit-stream','deep_reference']:
  t=subprocess.run(['llvm-readelf','--notes',f'mods/{m}.hsaco'],capture_output=True,text=True).stdout
  for blk in t.split('  - .args:')[1:]:
    g=lambda k:(re.search(r'\.'+k+r':\s+(\S+)',blk) or [0,'0'])[1]
    meta[(m,g('name'))]=(int(g('vgpr_count')),int(g('group_segment_fixed_size')))
sw=collections.OrderedDict()
for r in csv.DictReader(open('sweep.csv')): sw.setdefault(r['id'],{})[int(r['gridx'])]=float(r['us'])
# count per frame
cnt=collections.Counter((r['id'][:5] if r['id'].startswith('o900') else r['id'][:6],r['symbol'],r['grid']) for r in disp.values())
print('|id|核|次/帧|WG×线程|wave 数|wave/SIMD|VGPR/LDS|驻留上限 wave/SIMD|单 WG µs|全量 µs|单/全|')
print('|---|---|---:|---|---:|---:|---|---:|---:|---:|---:|')
for id,d in sw.items():
  r=disp[id];wg=int(r['grid']);th=int(r['threads']);wpg=math.ceil(th/32);waves=wg*wpg
  v,l=meta[(r['module'],r['symbol'])];va=math.ceil(v/8)*8
  occ=min(16,1536//va)  # 1536 VGPR/SIMD wave32 assumption
  if l: occ=min(occ,(65536//l)*wpg//2)
  tier='o900' if id.startswith('o900') else 'o1080'
  n=sum(1 for x in disp.values() if x['id'].startswith(tier+'-') and x['symbol']==r['symbol'] and x['grid']==r['grid'])
  one=min(d[x] for x in d if x<=2);full=d[max(d)]
  print(f"|{id}|{r['symbol']}|{n}|{wg}×{th}|{waves}|{waves/128:.1f}|{v}/{l}|{occ}|{one:.1f}|{full:.1f}|{one/full:.0%}|")
