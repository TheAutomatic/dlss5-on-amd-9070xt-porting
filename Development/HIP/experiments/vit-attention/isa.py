#!/usr/bin/env python3
"""Save disassembly, metadata and encoded-instruction histograms (not cycles)."""
import argparse,importlib.util,json,re,subprocess,collections
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--artifacts',type=Path,required=True);p.add_argument('--out',type=Path,required=True);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4];sp=importlib.util.spec_from_file_location('elf',r/'Development/tools/llvm-fork/compare-kernels.py');m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m)
objdump='/home/lmxxf/work/llvm-build-dlss5-gfx12/bin/llvm-objdump'
jobs=[('baseline',a.artifacts/'baseline/gfx1201/deep_fast-packed.hsaco','vit_attention_fused_640_bytein_bout'),('candidate',a.artifacts/'production/production-1/gfx1201/deep_fast-packed.hsaco','vit_attention_fused_640_bytein_bout'),('daniel050',a.artifacts/'daniel-050.hsaco','_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams'),('daniel051',a.artifacts/'daniel-051.hsaco','_Z12k_reg1d_attnILi1ELb0EEv15Reg1dAttnParams')]
out={};raw={}
for label,path,name in jobs:
 _,ks,syms=m.elf(path);raw[label]=syms[name][2]
 asm=subprocess.check_output([objdump,'-d','--mcpu=gfx1201','--disassemble-symbols='+name,str(path)],text=True);(a.out/(label+'.s')).write_text(asm)
 lines=[]
 for line in asm.splitlines():
  q=re.match(r'\s*([a-z][a-z0-9_]*)\s+(.*?)\s*//\s*([0-9A-Fa-f]+):',line)
  if q:lines.append((int(q[3],16),q[1],q[2]))
 backs=[]
 for pc,op,args in lines:
  if op.startswith('s_cbranch'):
   displacement=int(args.split()[0],0)
   if displacement>=32768:displacement-=65536
   dest=pc+4+4*displacement
   if dest<pc:backs.append((dest,pc))
 lo=min(x[0] for x in backs);hi=max(x[1] for x in backs)
 regions={}
 for region,ins in [('all',lines),('setup',[x for x in lines if x[0]<lo]),('key_loop',[x for x in lines if lo<=x[0]<=hi]),('epilogue',[x for x in lines if x[0]>hi])]:
  hist=collections.Counter(x[1] for x in ins);family=collections.Counter()
  for _,op,_ in ins:
   kind='WMMA' if 'wmma' in op else 'VMEM' if op.startswith(('global_','buffer_','flat_')) else 'DS_shuffle' if 'bpermute' in op else 'DS_memory' if op.startswith('ds_') else 'WAIT' if op.startswith(('s_wait','s_delay')) else 'BRANCH_EXEC' if ('branch' in op or 'exec' in op) else 'VALU' if op.startswith('v_') else 'SALU'
   family[kind]+=1
  regions[region]=dict(encoded_packets=len(ins),families=dict(family),mnemonics=dict(sorted(hist.items())))
 out[label]=dict(symbol=name,code_bytes=len(raw[label]),metadata=ks[name],loop_offsets=[hex(lo-syms[name][0]),hex(hi-syms[name][0])],regions=regions)
out['daniel_code_same_050_051']=raw['daniel050']==raw['daniel051']
(a.out/'isa.json').write_text(json.dumps(out,indent=2)+'\n')
print(json.dumps({k:dict(code_bytes=v['code_bytes'],loop_offsets=v['loop_offsets'],loop=v['regions']['key_loop']['families']) for k,v in out.items() if isinstance(v,dict)},indent=2))
