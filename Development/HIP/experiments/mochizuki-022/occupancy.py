from pathlib import Path
out=Path('/tmp/mochizuki-022/hip')
# Reserve LDS only to cap occupancy, not to hold or change model data.
def pad(macro):return '''
#if '''+macro+'''
 __attribute__((shared)) volatile uint occ_pad['''+macro+'''/4];
 if(tokens==0xffffffffu){uint lane=__builtin_amdgcn_workitem_id_x();uint i=(bid()*131u+lane)%('''+macro+'''/4);occ_pad[i]=i;__builtin_amdgcn_s_barrier();if(occ_pad[(i+1)%('''+macro+'''/4)]==5u)out[0]=0.f;}
#endif
'''
p=out/'c512_m32_deep.inc';s=p.read_text();s='#ifndef C512_MIX_OCC_LDS\n#define C512_MIX_OCC_LDS 0\n#endif\n'+s;key='WAVE void split_mix_blocked_h16w_m32(const float*in,const float*w,float*out,uint tokens){';assert s.count(key)==1;s=s.replace(key,key+pad('C512_MIX_OCC_LDS'));p.write_text(s)
p=out/'deep_fast.hip';s=p.read_text();s='#ifndef VIT_CONTRACT_OCC_LDS\n#define VIT_CONTRACT_OCC_LDS 0\n#endif\n'+s
key='DEV void vit_contract_blocked_body(';a=s.index(key);b=s.index('{',a);s=s[:b+1]+pad('VIT_CONTRACT_OCC_LDS')+s[b+1:];p.write_text(s)
