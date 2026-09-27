"""Reviewed gfx1201 loop counts, fixed 1024/4096 dimensions; conditional epilogues are upper work bills."""
from pathlib import Path
import importlib.util,collections,re,json,sys,hashlib
ROOT=Path(__file__).resolve().parents[4]
s=importlib.util.spec_from_file_location('S',ROOT/'Development/results/aco-isa-20260927/tools/isa_stats.py');S=importlib.util.module_from_spec(s);s.loader.exec_module(S)
conf={
 'vit_stream_project_n64_b': ([(82,515,4),(408,464,4)],(112,400),256),
 'vit_stream_project_n64_h': ([(90,1427,4)],(1114,1427),256),
 'vit_stream_project_n64_bh': ([(81,537,4),(431,487,4)],(111,423),256),
 'vit_stream_qkv_frag_hin': ([(103,177,8)],None,130),
 'vit_stream_contract_frag_hout': ([(392,457,16),(505,571,16),(615,681,16),(704,760,16)],None,1024),
 'vit_qkv_project_normalize_fused_f16compact_fp8_frag': ([(103,169,32)],None,130),
 'vit_contract_blocked_fp8_frag': ([(403,468,16),(516,582,16),(626,692,16),(715,771,16)],None,1024),
}
x={}
for arg in sys.argv[1:]:
 p=Path(arg);text=p.read_text()
 for k,b in S.llvm_kernels(text):
  if k not in conf or k in x:continue
  loops,once,wmma=conf[k]
  if 'build-U' in str(p) and k=='vit_stream_qkv_frag_hin':loops=[(103,130,32)]
  c=collections.Counter();ops=collections.Counter();r=w=0
  for a,z,n in loops:assert '.LBB' in b[a] and 'branch' in b[z],(k,a,z)
  for i,l in enumerate(b):
   mul=1
   for a,z,n in loops:
    if a<=i<=z:mul*=n
   if once and once[0]<=i<=once[1]:mul=1
   for op,_ in S.ops_of([l]):
    c[S.classify(op)]+=mul;ops[op]+=mul
    m=re.fullmatch(r'global_(load|store)_[bu](8|16|32|64|128)',op)
    if m:
     if m[1]=='load':r+=mul*int(m[2])//8
     else:w+=mul*int(m[2])//8
  assert c['WMMA']==wmma,(k,c)
  x[k]={'classes':dict(c),'opcodes':dict(ops),'read_bytes_per_lane':r,'write_bytes_per_lane':w,'loops':loops,'p0':once,'isa_sha256':hashlib.sha256(text.encode()).hexdigest()}
print(json.dumps(x,indent=2))
