"""Only FFN feature bypasses half RTZ; residual/store/activation unchanged."""
from pathlib import Path
import argparse,importlib.util,json,hashlib
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True);r=Path(__file__).resolve().parents[4]
sp=importlib.util.spec_from_file_location('recipe',r/'Development/tools/llvm-fork/compile-modules.py');m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m);row=next(x for x in m.recipe(r/'hip')if x[0]=='c32-wave1-fast');assert row[1]=='llvm23'
s=row[2];needle='   for(uint e=0;e<8;e++)CW_Q8_SET(a,e,float(rounded[e]));';assert s.count(needle)==1
changed=s.replace(needle,'   for(uint e=0;e<8;e++)CW_Q8_SET(a,e,ffn[ci][e]);',1)
# Exact residual conversion and memcpy statement must remain identical.
res='h8 rounded=cw_rtz_half8(ffn[ci]);__builtin_memcpy(residual+((qt*2+ci)*32+(g*16+r))*8,&rounded,16);'
assert s.count(res)==changed.count(res)==1
(a.output/'old.hip').write_text(s);(a.output/'new.hip').write_text(changed)
gold='''
CW_ENTRY void c32_feature_same_a(const float*values,uint*out,uint count){
 uint lane=__builtin_amdgcn_workitem_id_x()+__builtin_amdgcn_workgroup_id_x()*32;
 f8 a{};for(uint e=0;e<8;e++){uint i=lane*8+e;a[e]=i<count?values[i]:0.f;}
 h8 rold=cw_rtz_half8(a),rnew=cw_rtz_half8(a);float old[8],direct[8];
 for(uint e=0;e<8;e++){old[e]=float(rold[e]);direct[e]=a[e];}
 i2 qo=cw_pack8<2,0>(old),qn=cw_pack8<2,0>(direct);
 using raw4=unsigned int __attribute__((ext_vector_type(4)));raw4 rbo=__builtin_bit_cast(raw4,rold),rbn=__builtin_bit_cast(raw4,rnew);
 for(uint e=0;e<8;e++){uint i=lane*8+e;if(i<count){out[i*4]=(rbo[e/2]>>(16*(e%2)))&65535u;out[i*4+1]=(rbn[e/2]>>(16*(e%2)))&65535u;out[i*4+2]=(uint(qo[e/4])>>(8*(e%4)))&255u;out[i*4+3]=(uint(qn[e/4])>>(8*(e%4)))&255u;}}
}
'''
(a.output/'gold.hip').write_text(s+gold)
(a.output/'source.json').write_text(json.dumps({'row':row[0],'compiler':row[1],'defines':row[3],'opts':row[-1],'residual_statement_sha':hashlib.sha256(res.encode()).hexdigest(),'old_source_sha':hashlib.sha256(s.encode()).hexdigest(),'new_source_sha':hashlib.sha256(changed.encode()).hexdigest(),'scope':'onlyone CW_RTZ_PAIR feature exit changed; all residual rounding/stores and all other math unchanged; intended numerical difference'},indent=2)+'\n')
