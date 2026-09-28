exec(open('/tmp/aco-lineup/phase.py').read().split('out={}')[0])
p=Path('/tmp/aco-lineup/multihead-fast-padded-wave-packed-debug.hsaco.s');out={}
for k,b in S.llvm_kernels(p.read_text()):
 if k not in ('mh_ffn_fused_c256_frag_project_mapped_g128_qkv_fb_pdl','mh_ffn_fused_c256_frag_project_mapped_g128_qkv_bytein_fb_pdl'):continue
 # Local e/tile loops are unrolled; residual CFG backedges are PDL waits / divergent dispatch paths.
 cur=0;ops=collections.defaultdict(collections.Counter);rows=[]
 for i,l in enumerate(b):
  if '.loc' in l:
   ns=[int(x) for x in re.findall(r'probe.hip:(\d+):\d+',l)];ns=[x for x in ns if 647<=x<=813];cur=ns[-1] if ns else 0
  phase='activation' if cur==718 else 'other'
  for op,_ in S.ops_of([l]):
   ops[phase][op]+=1
   if phase=='activation':rows.append(dict(line=i+1,op=op,isa=l.strip()))
 out[k]={'ops':ops,'activation_rows':rows}
Path('/tmp/aco-lineup/c256-ffn-phases.json').write_text(json.dumps(out,indent=2))
for k,v in out.items():print(k,v['ops'].get('activation'))
