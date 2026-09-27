from pathlib import Path
root=Path(__file__).resolve().parents[4];out=Path('/tmp/c512-round1/hip')
p=out/'c512_m32_deep.inc';s=(root/'hip/c512_m32_deep.inc').read_text();a=s.index(' for(uint j=0;j<4;j++)for(uint e=0;e<8;e++)out[');old=s[a:s.rindex('\n}')]
helper='''#ifndef C512_MIX_PAIR
#define C512_MIX_PAIR 0
#endif
#if C512_MIX_PAIR
DEV void c512_rtz_pair(float a,float b,float&x,float&y){uint h;asm("v_cvt_pkrtz_f16_f32 %0, %1, %2":"=v"(h):"v"(a),"v"(b));asm("v_cvt_f32_f16 %0, %1":"=v"(x):"v"(h));uint hi=h>>16;asm("v_cvt_f32_f16 %0, %1":"=v"(y):"v"(hi));}
DEV void c512_f_pair(float a,float b,float&x,float&y){float ca=__builtin_fminf(__builtin_fmaxf(a,-448.f),448.f),cb=__builtin_fminf(__builtin_fmaxf(b,-448.f),448.f);int q=__builtin_amdgcn_cvt_pk_fp8_f32(ca,cb,0,false);x=(bits(a)&0x7fffffff)==0?0.f:__builtin_amdgcn_cvt_f32_fp8(q,0);y=(bits(b)&0x7fffffff)==0?0.f:__builtin_amdgcn_cvt_f32_fp8(q,1);}
#endif
'''
new='''
#if C512_MIX_PAIR
 for(uint t=0;t<2;t++){if(t&&!two)break;f8*acc=t?acc1:acc0;for(uint j=0;j<4;j++)for(uint e=0;e<8;e+=2){float a,b,x,y;c512_rtz_pair(acc[j][e],acc[j][e+1],a,b);c512_f_pair(a,b,x,y);out[(first+t*16+gr()*8+e)*512+row+j*16+rc()]=x;out[(first+t*16+gr()*8+e+1)*512+row+j*16+rc()]=y;}}
#else
'''+old+'\n#endif'
s=helper+s[:a]+new+s[s.rindex('\n}'):];p.write_text(s)
p=out/'c512_m32_mh.inc';s=(root/'hip/c512_m32_mh.inc').read_text();s='#ifndef C512_QKV_DIRECT\n#define C512_QKV_DIRECT 0\n#endif\n'+s;s=s.replace('q8(F(acc[n][e]*raw[16*65+(n/2)*16+row]))','(C512_QKV_DIRECT?q8_fused_round(acc[n][e]*raw[16*65+(n/2)*16+row]):q8(F(acc[n][e]*raw[16*65+(n/2)*16+row])))');p.write_text(s)
p=out/'c512_m32_deep.inc';s=p.read_text();orig=(root/'hip/c512_m32_deep.inc').read_text();a=orig.index('WAVE void split_mix_blocked_h16w_m32');n=orig[a:];z=n.index('#if C512_ZERO_PAD_900');end=n.index('#endif',z)+len('#endif');n=n[:z]+n[end:];n=n.replace('split_mix_blocked_h16w_m32','split_mix_blocked_h16w_m32_n32').replace('bid()/8*32,row=bid()%8*64','bid()/16*32,row=bid()%16*32').replace('acc0[4]{},acc1[4]{}','acc0[2]{},acc1[2]{}').replace('j<4','j<2');s+='\n#ifndef C512_MIX_N32\n#define C512_MIX_N32 0\n#endif\n#if C512_MIX_N32\n'+n+'\n#endif\n';p.write_text(s)
p=out/'c512_m32_mh.inc';s=p.read_text();s='#ifndef C512_QKV_LDS_ALIAS\n#define C512_QKV_LDS_ALIAS 0\n#endif\n'+s
old=' __attribute__((shared)) c5u4 tile[16*4];';assert old in s;s=s.replace(old,'''#if C512_QKV_LDS_ALIAS
 // raw[0..1039] is dead after the serial norm; invs live at raw[1040..1071].
 // Output needs only the first 1024 bytes, disjoint from all invs. Existing fences bracket both lives.
 c5u4*tile=reinterpret_cast<c5u4*>(raw);
#else
 __attribute__((shared)) c5u4 tile[16*4];
#endif''');s=s.replace('__attribute__((shared)) float raw[17*65];','#if C512_QKV_LDS_ALIAS\n __attribute__((shared,aligned(16))) float raw[17*65];\n#else\n __attribute__((shared)) float raw[17*65];\n#endif');p.write_text(s)
