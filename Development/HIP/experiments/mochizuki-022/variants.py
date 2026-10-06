from pathlib import Path
root=Path(__file__).resolve().parents[4];out=Path('/tmp/mochizuki-022/hip')
p=out/'wave_owned_c32.inc';s=(root/'hip/wave_owned_c32.inc').read_text()
helper='''// Exact representation changes only: keep every arithmetic rounding, reuse its half bits.
#ifndef CW_INPUT_HALF
#define CW_INPUT_HALF 0 /* bit0: local post Hrtz value; bit1: mapped input from half/FP8 producers */
#endif
#ifndef CW_PREFIX_HALF_SOURCE
#define CW_PREFIX_HALF_SOURCE 0
#endif
#if CW_PREFIX_HALF_SOURCE
using cw_pv_t=_Float16;
DEV cw_pv_t cw_prefix_rtz(float x){uint p;asm("v_cvt_pkrtz_f16_f32 %0, %1, %1":"=v"(p):"v"(x));return __builtin_bit_cast(_Float16,(unsigned short)p);}
DEV cw_pv_t cw_prefix_shuffle(cw_pv_t x,uint lane){uint p=uint(__builtin_bit_cast(unsigned short,x));p=uint(__builtin_amdgcn_ds_bpermute(lane*4,int(p)));return __builtin_bit_cast(_Float16,(unsigned short)p);}
#else
using cw_pv_t=float;
DEV cw_pv_t cw_prefix_rtz(float x){return Hrtz(x);}
DEV cw_pv_t cw_prefix_shuffle(cw_pv_t x,uint lane){return __builtin_bit_cast(float,__builtin_amdgcn_ds_bpermute(lane*4,__builtin_bit_cast(int,x)));}
#endif
'''
s=helper+s
assert s.count('cw_clampf(float((_Float16)v),-448.f,448.f)')==2
s=s.replace('cw_clampf(float((_Float16)v),-448.f,448.f)','cw_clampf((CW_INPUT_HALF&(Post?1u:2u))?v:float((_Float16)v),-448.f,448.f)')
a=s.index('   h8 a{};\n   {const float*rgba=');b=s.index('\n#else\n   float pv[16]',a);t=s[a:b]
t=t.replace('float gc=Hrtz(','cw_pv_t gc=cw_prefix_rtz(').replace('gs=Hrtz(','gs=cw_prefix_rtz(')
t=t.replace('float g0=__builtin_bit_cast(float,__builtin_amdgcn_ds_bpermute((r+16)*4,__builtin_bit_cast(int,gc)));','cw_pv_t g0=cw_prefix_shuffle(gc,r+16);')
t=t.replace('float red=Hrtz(','cw_pv_t red=cw_prefix_rtz(').replace('green=Hrtz(','green=cw_prefix_rtz(').replace('blue=Hrtz(','blue=cw_prefix_rtz(')
t=t.replace('float hr=red','cw_pv_t hr=red')
for c in ['hr','hg','hb']:t=t.replace(c+'=Hrtz(',c+'=cw_prefix_rtz(')
t=t.replace('const float lo[8]','const cw_pv_t lo[8]')
s=s[:a]+t+s[b:];p.write_text(s)
