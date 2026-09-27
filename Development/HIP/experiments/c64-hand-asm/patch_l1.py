#!/usr/bin/env python3
"""Hand edit of c64_wave2_bi_bo (P recipe, gfx1201), FFN hidden loop (.LBB91_3, x16 per window).
Per half-iteration: the 8 final products x*c and their 8 '+0' (-0 -> +0) adds become 4 v_dual_fmaak_f32 (x*c + 0, one
rounding: identical bits, -0+(+0)=+0), and the two 'v_mov v38/v39, 0' pre-zeroings go (both 16-bit halves of each
pack register are written by cvt_pk). s_delay_alu hints inside the rewritten spans are dropped (hints only).
usage: patch_l1.py base.s out.s"""
import sys
src=open(sys.argv[1]).read().split('\n')
s=next(i for i,l in enumerate(src) if l.startswith('c64_wave2_bi_bo:'))
e=next(i for i in range(s,len(src)) if src[i].startswith('.Lfunc_end'))
body=src[s:e]
def code(l):return l.split(';')[0].strip()
def find_seq(start,seq):
    """index of the first line (>=start) where the non-comment instruction lines match seq in order"""
    for i in range(start,len(body)):
        j=i;k=0
        while j<len(body) and k<len(seq):
            c=code(body[j])
            if not c or c.startswith('s_delay_alu'): j+=1;continue
            if c!=seq[k]:break
            j+=1;k+=1
        if k==len(seq):return i,j
    raise SystemExit('pattern not found: '+seq[0])
K='0x3f650000'
first_old=[
f'v_dual_add_f32 v61, {K}, v61 :: v_dual_add_f32 v66, {K}, v66',
f'v_dual_add_f32 v63, {K}, v63 :: v_dual_mul_f32 v40, v40, v62',
's_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_3)',
f'v_dual_add_f32 v65, {K}, v65 :: v_dual_mul_f32 v38, v38, v47',
f'v_dual_add_f32 v67, {K}, v67 :: v_dual_mul_f32 v42, v42, v64',
's_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)',
'v_dual_mul_f32 v39, v39, v61 :: v_dual_mul_f32 v44, v44, v66',
'v_mul_f32_e32 v41, v41, v63',
's_delay_alu instid0(VALU_DEP_4) | instskip(NEXT) | instid1(VALU_DEP_4)',
'v_mul_f32_e32 v43, v43, v65',
'v_mul_f32_e32 v45, v45, v67',
's_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1',
'v_dual_add_f32 v47, 0, v38 :: v_dual_mov_b32 v38, 0',
'v_dual_add_f32 v61, 0, v39 :: v_dual_add_f32 v42, 0, v42',
'v_dual_add_f32 v43, 0, v43 :: v_dual_add_f32 v40, 0, v40',
'v_mov_b32_e32 v39, 0',
's_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_3)',
'v_cvt_pk_fp8_f32 v38, v47, v61',
'v_add_f32_e32 v41, 0, v41',
'v_cvt_pk_fp8_f32 v39, v42, v43',
'v_dual_add_f32 v42, 0, v44 :: v_dual_add_f32 v43, 0, v45',
's_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)',
'v_cvt_pk_fp8_f32 v38, v40, v41 op_sel:[0,0,1]',
'v_cvt_pk_fp8_f32 v39, v42, v43 op_sel:[0,0,1]']
first_new=[
f'v_dual_add_f32 v61, {K}, v61 :: v_dual_add_f32 v66, {K}, v66',
f'v_add_f32_e32 v63, {K}, v63',
f'v_add_f32_e32 v65, {K}, v65',
f'v_add_f32_e32 v67, {K}, v67',
'v_dual_fmaak_f32 v38, v38, v47, 0x0 :: v_dual_fmaak_f32 v39, v39, v61, 0x0',
'v_dual_fmaak_f32 v40, v40, v62, 0x0 :: v_dual_fmaak_f32 v41, v41, v63, 0x0',
'v_dual_fmaak_f32 v42, v42, v64, 0x0 :: v_dual_fmaak_f32 v43, v43, v65, 0x0',
'v_dual_fmaak_f32 v44, v44, v66, 0x0 :: v_dual_fmaak_f32 v45, v45, v67, 0x0',
's_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1',
'v_cvt_pk_fp8_f32 v38, v38, v39',
'v_cvt_pk_fp8_f32 v39, v42, v43',
'v_cvt_pk_fp8_f32 v38, v40, v41 op_sel:[0,0,1]',
'v_cvt_pk_fp8_f32 v39, v44, v45 op_sel:[0,0,1]']
second_old=[
f'v_dual_add_f32 v47, {K}, v47 :: v_dual_mul_f32 v44, v52, v44',
's_delay_alu instid0(VALU_DEP_4)',
f'v_add_f32_e32 v63, {K}, v63',
f'v_add_f32_e32 v61, {K}, v61',
f'v_add_f32_e32 v65, {K}, v65',
'v_mul_f32_e32 v45, v53, v45',
'v_mul_f32_e32 v47, v54, v47',
'v_dual_mul_f32 v53, v56, v62 :: v_dual_mul_f32 v54, v57, v63',
'v_dual_mul_f32 v52, v55, v61 :: v_dual_mul_f32 v55, v58, v64',
's_wait_loadcnt 0x1',
'v_wmma_f32_16x16x16_fp8_fp8 v[9:16], v[40:41], v[38:39], v[9:16]',
'v_mul_f32_e32 v40, v59, v65',
's_wait_loadcnt 0x0',
'v_wmma_f32_16x16x16_fp8_fp8 v[1:8], v[42:43], v[38:39], v[1:8]',
's_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1',
'v_dual_add_f32 v41, 0, v44 :: v_dual_add_f32 v42, 0, v45',
'v_dual_mov_b32 v38, 0 :: v_dual_add_f32 v43, 0, v53',
'v_dual_add_f32 v44, 0, v54 :: v_dual_mov_b32 v39, 0',
'v_add_f32_e32 v40, 0, v40',
's_delay_alu instid0(VALU_DEP_3) | instskip(SKIP_1) | instid1(VALU_DEP_4)',
'v_cvt_pk_fp8_f32 v38, v41, v42',
'v_dual_add_f32 v41, 0, v47 :: v_dual_add_f32 v42, 0, v52',
'v_cvt_pk_fp8_f32 v39, v43, v44',
'v_add_f32_e32 v43, 0, v55',
's_delay_alu instid0(VALU_DEP_3) | instskip(NEXT) | instid1(VALU_DEP_2)',
'v_cvt_pk_fp8_f32 v38, v41, v42 op_sel:[0,0,1]',
'v_cvt_pk_fp8_f32 v39, v43, v40 op_sel:[0,0,1]']
second_new=[
f'v_add_f32_e32 v47, {K}, v47',
f'v_add_f32_e32 v63, {K}, v63',
f'v_add_f32_e32 v61, {K}, v61',
f'v_add_f32_e32 v65, {K}, v65',
'v_dual_fmaak_f32 v52, v52, v44, 0x0 :: v_dual_fmaak_f32 v53, v53, v45, 0x0',
'v_dual_fmaak_f32 v54, v54, v47, 0x0 :: v_dual_fmaak_f32 v55, v55, v61, 0x0',
's_wait_loadcnt 0x1',
'v_wmma_f32_16x16x16_fp8_fp8 v[9:16], v[40:41], v[38:39], v[9:16]',
's_wait_loadcnt 0x0',
'v_wmma_f32_16x16x16_fp8_fp8 v[1:8], v[42:43], v[38:39], v[1:8]',
's_setreg_imm32_b32 hwreg(HW_REG_MODE, 23, 1), 1',
'v_dual_fmaak_f32 v56, v56, v62, 0x0 :: v_dual_fmaak_f32 v57, v57, v63, 0x0',
'v_dual_fmaak_f32 v58, v58, v64, 0x0 :: v_dual_fmaak_f32 v59, v59, v65, 0x0',
'v_cvt_pk_fp8_f32 v38, v52, v53',
'v_cvt_pk_fp8_f32 v38, v54, v55 op_sel:[0,0,1]',
'v_cvt_pk_fp8_f32 v39, v56, v57',
'v_cvt_pk_fp8_f32 v39, v58, v59 op_sel:[0,0,1]']
loop=next(i for i,l in enumerate(body) if l.startswith('.LBB91_3:'))
out=body[:]
for old,new in ((second_old,second_new),(first_old,first_new)):
    a,b=find_seq(loop,[x for x in old if not x.startswith('s_delay_alu')])
    out[a:b]=['\t'+x for x in new]
open(sys.argv[2],'w').write('\n'.join(src[:s]+out+src[e:]))
print('patched; kernel lines',len(body),'->',len(out))
