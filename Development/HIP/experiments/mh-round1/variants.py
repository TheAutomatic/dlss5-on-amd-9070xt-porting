from pathlib import Path
import importlib.util,collections,re,json,sys
import cfg
ROOT=Path(__file__).resolve().parents[4]
s=importlib.util.spec_from_file_location('S',ROOT/'Development/results/aco-isa-20260927/tools/isa_stats.py');S=importlib.util.module_from_spec(s);s.loader.exec_module(S)
out={}
for path in sys.argv[1:]:
 p=Path(path);text=p.read_text();rows={}
 for k,b in S.llvm_kernels(text):
  if not re.match(r'c(?:64|128|256)_(wave2|attn_wave)',k):continue
  static=collections.Counter(S.classify(op) for op,_ in S.ops_of(b));ls=cfg.loops(b);d=collections.Counter();trip=[]
  for x in ls:
   if any('s_sleep' in b[i] for i in x['lines']):t=1
   elif 'attn' in k and any(x['lines']<y['lines'] for y in ls):t=2
   else:t=4
   trip.append(t)
  for i,l in enumerate(b):
   w=1
   for loop,t in zip(ls,trip):
    if i in loop['lines']:w*=t
   for op,_ in S.ops_of([l]):d[S.classify(op)]+=w
  expected=232 if 'attn' in k else 168+int(re.match(r'c(\d+)',k)[1])*9//2
  if 'build-T' not in str(p):assert d['WMMA']==expected,(k,d['WMMA'],expected)
  resources={}
  m=re.search(r'\.amdhsa_kernel '+k+r'(.*?)\.end_amdhsa_kernel',text,re.S)
  if m:resources={a:int(v) for a,v in re.findall(r'\.amdhsa_(next_free_vgpr|group_segment_fixed_size|private_segment_fixed_size) (\d+)',m[1])}
  rows[k]={'static':dict(static),'all_branch_upper_per_wave':dict(d),'resources':resources,'loop_trips':trip}
 out[str(p)]=rows
print(json.dumps(out,indent=2))
