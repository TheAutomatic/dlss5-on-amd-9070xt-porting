from pathlib import Path
import importlib.util,collections,json,sys,re
ROOT=Path(__file__).resolve().parents[4]
s=importlib.util.spec_from_file_location('S',ROOT/'Development/results/aco-isa-20260927/tools/isa_stats.py');S=importlib.util.module_from_spec(s);s.loader.exec_module(S)
out={}
for k,b in S.llvm_kernels(Path(sys.argv[1]).read_text()):
 if k not in ('split_mix_m32_hout','split_ffn_t8_hin','split_ffn_fused_fp8_t8'):continue
 c=collections.Counter();ops=collections.Counter();r=w=0
 for i,l in enumerate(b):
  mul=32 if k=='split_mix_m32_hout' and 77<=i<=156 else 1
  for op,_ in S.ops_of([l]):
   c[S.classify(op)]+=mul;ops[op]+=mul
   m=re.fullmatch(r'global_(load|store)_[bu](8|16|32|64|128)',op)
   if m:
    if m[1]=='load':r+=mul*int(m[2])//8
    else:w+=mul*int(m[2])//8
 out[k]={'classes':dict(c),'opcodes':dict(ops),'read_bytes_per_lane':r,'write_bytes_per_lane':w}
print(json.dumps(out,indent=2))
