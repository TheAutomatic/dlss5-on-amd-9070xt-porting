#!/usr/bin/env python3
"""Static screen for the compiler sweep: per hot kernel, metadata (VGPR/SGPR/spill/scratch/LDS), occupancy estimate and
instruction mix, compared with the base build. usage: isa_stat.py <base-dir> <cand-dir> [module ...]  (dirs hold <module>.hsaco)"""
import re, subprocess, sys, collections, os, hashlib
B = '/home/lmxxf/work/llvm-build-dlss5-gfx12/bin/'
HOT = {
 'c64-wave2': ['c128_wave2_bi_bo', 'c64_wave2_bi_bo'],
 'swin-persistent': ['sp_run256_w16'],
 'c32-wave1': ['c32_wave1_post_b8', 'c32_wave1_prefix_b8d', 'c32_wave1_chain', 'c32_wave1_up_b8', 'c32_wave1_finish_dcrop_b8d', 'c32_wave1_mapped_b8', 'c32_wave1_finish_b8'],
 'c512-m32-mh': ['c512_qkv_attention_compact'],
 'c512-m32-deep': ['split_ffn_one_w2f8'],
 'vit-stream': ['vit_stream_contract_frag_hout', 'vit_stream_qkv_frag_hin_w5f8'],
 'multihead-fast-padded-wave-packed': ['mh_attention_project_frag_c512', 'mh_ffn_fused_c256_frag_project_mapped_g128_qkv_bytein_fb_pdl'],
 'deep_fast-packed': ['split_projection_frag', 'vit_attention_fused_400_bytein_bout', 'vit_attention_fused_640_bytein_bout', 'vit_expand_blocked_fp8_frag_bytein'],
}
def meta(f):
    out = subprocess.run([B + 'llvm-readobj', '--notes', f], capture_output=True, text=True).stdout
    ks = {}
    for blk in re.split(r'\n\s+- \.', out):
        m = re.search(r'\.name:\s+(\S+)', blk)
        if not m: continue
        g = lambda k: int(re.search(r'\.' + k + r':\s+(\d+)', blk).group(1)) if re.search(r'\.' + k + r':\s+(\d+)', blk) else -1
        ks[m.group(1)] = dict(v=g('vgpr_count'), s=g('sgpr_count'), vsp=g('vgpr_spill_count'), ssp=g('sgpr_spill_count'), priv=g('private_segment_fixed_size'), lds=g('group_segment_fixed_size'), wg=g('max_flat_workgroup_size'))
    return ks
def isa(f, k):
    s = subprocess.run([B + 'llvm-objdump', '-d', '--mcpu=gfx1201', '--disassemble-symbols=' + k, f], capture_output=True, text=True).stdout
    ins = [l.split('//')[0].strip() for l in s.splitlines() if l.startswith('\t') or l.startswith('  ')]
    ins = [i for i in ins if i]
    ops = [i.split()[0] for i in ins]
    c = collections.Counter()
    for o in ops:
        if 'wmma' in o: c['wmma'] += 1
        elif o.startswith('v_dual'): c['vopd'] += 1
        elif o.startswith('v_'): c['valu'] += 1
        elif o.startswith(('global_load', 'buffer_load')): c['vmem_ld'] += 1
        elif o.startswith(('global_store', 'buffer_store')): c['vmem_st'] += 1
        elif o.startswith('ds_'): c['lds'] += 1
        elif o.startswith('s_wait_'): c['wait'] += 1
        elif o == 's_delay_alu': c['delay'] += 1
        elif o.startswith('s_nop'): c['nop'] += 1
        elif o.startswith('s_'): c['salu'] += 1
    c['n'] = len(ops)
    body = '\n'.join(re.sub(r'\s+', ' ', i) for i in ins)
    return c, hashlib.sha1(body.encode()).hexdigest()[:8]
def occ(v):
    if v <= 0: return 0
    g = (v + 23) // 24 * 24
    return min(16, 1536 // g)
def main():
    bd, cd = sys.argv[1], sys.argv[2]
    mods = sys.argv[3:] or list(HOT)
    for m in mods:
        bf, cf = os.path.join(bd, m + '.hsaco'), os.path.join(cd, m + '.hsaco')
        if not os.path.exists(cf): continue
        bm, cm = meta(bf), meta(cf)
        for k in HOT[m]:
            if k not in bm or k not in cm: continue
            (bc, bh), (cc, ch) = isa(bf, k), isa(cf, k)
            a, b = bm[k], cm[k]
            same = 'SAME' if bh == ch and a == b else 'diff'
            print(f"{m:34s} {k:58s} {same} vgpr {a['v']:3d}->{b['v']:3d} occ {occ(a['v'])}->{occ(b['v'])} spill {b['vsp']}/{b['ssp']} priv {b['priv']} n {bc['n']}->{cc['n']} wait {bc['wait']}->{cc['wait']} delay {bc['delay']}->{cc['delay']} vopd {bc['vopd']}->{cc['vopd']} valu {bc['valu']}->{cc['valu']}")
main()
