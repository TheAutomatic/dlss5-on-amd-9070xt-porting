"""Change only 640 bytein+bout V fragment loading, preserving producer/math."""
from pathlib import Path
import argparse,importlib.util,json,hashlib
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);r=Path(__file__).resolve().parents[4]
sp=importlib.util.spec_from_file_location('recipe',r/'Development/tools/llvm-fork/compile-modules.py');m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m);row=next(x for x in m.recipe(r/'hip')if x[0]=='deep_fast-packed-fast');s=row[2]
start=s.index('DEV void vit_attention_transposed_score_body');end=s.index('// FAST TIER',start)if '// FAST TIER' in s[start:]else s.index('DEV void vit_attention_fused_body',start)
# Search only the transposed-score function body, selected by production defines.
part=s[start:end]
needle='for(uint c=0;c<2;c++){i2 y{};for(uint e=0;e<8;e++){uint vkey=key+gr()*8+e;if constexpr(ByteInput){uint b=in8[(2*tokens+vkey)*1024+head*32+c*16+rc()];y[e/4]=int(uint(y[e/4])|(b<<(8*(e%4))));}else pack(y,e,in[(2*tokens+vkey)*1024+head*32+c*16+rc()]);}'
assert part.count(needle)==1
new='''for(uint c=0;c<2;c++){i2 y{};
  if constexpr(MAXT==640&&ByteInput&&ByteOut){
   uint lane=__builtin_amdgcn_workitem_id_x(),readrow=(lane/8)*4+(lane&3),readcol=(lane&4)?8:0;
   using vit_gi2=i2 __attribute__((address_space(1)));
   y=__builtin_amdgcn_global_load_tr_b64_v2i32((vit_gi2*)(in8+(2*tokens+key+readrow)*1024+head*32+c*16+readcol));
  }else for(uint e=0;e<8;e++){uint vkey=key+gr()*8+e;if constexpr(ByteInput){uint b=in8[(2*tokens+vkey)*1024+head*32+c*16+rc()];y[e/4]=int(uint(y[e/4])|(b<<(8*(e%4))));}else pack(y,e,in[(2*tokens+vkey)*1024+head*32+c*16+rc()]);}'''
changed=s[:start]+part.replace(needle,new)+s[end:];(a.output/'old.hip').write_text(s);(a.output/'new.hip').write_text(changed)
(a.output/'source.json').write_text(json.dumps({'row':row[0],'compiler':row[1] or 'COMGR','defines':row[3],'opts':row[-1],'oldSHA':hashlib.sha256(s.encode()).hexdigest(),'newSHA':hashlib.sha256(changed.encode()).hexdigest(),'scope':'sole V load inside production transposed-score body MAXT640/ByteInput/ByteOut; other specializations remain old, Q/K/P/den/AV/WMMA/store/producer unchanged'},indent=2)+'\n')
