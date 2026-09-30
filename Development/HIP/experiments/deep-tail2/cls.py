import re,sys,collections
def ops(path):
    out=[]
    for l in open(path):
        s=l.strip()
        if not s or s.startswith(('/',';','.')) or s.endswith(':') or s.startswith('<') : continue
        m=re.match(r'^(?:[0-9a-f]+:\s+(?:[0-9a-f]{8}\s+)+)?([a-z_][a-z0-9_]*)',s)
        if not m: continue
        o=m.group(1)
        if re.match(r'^[0-9a-f]+$',o): continue
        out.append(o)
    return out
def fam(o):
    if o.startswith('v_wmma'): return 'WMMA'
    if o.startswith('s_wait'): return 'wait'
    if o.startswith(('s_delay_alu','s_nop','s_clause')): return 'sched'
    if o.startswith(('ds_',)): return 'LDS'
    if o.startswith(('global_','buffer_','s_load','s_buffer')): return 'MEM'
    if o.startswith('s_'): return 'SALU'
    if o.startswith('v_'):
        if o.startswith('v_dual'): return 'V:dual'
        if 'cvt' in o or o.startswith(('v_pack_b32_f16','v_fma_mix')): return 'V:cvt'
        if re.match(r'v_(fma|fmac|mul_f|add_f|sub_f|subrev_f|pk_fma|pk_mul|pk_add|fmaak|fmamk|dot)',o): return 'V:fmul/add'
        if re.match(r'v_(med3|max|min|cndmask|cmp|cmpx|maxmin|minmax)',o): return 'V:cmp/sel'
        if re.match(r'v_(rsq|rcp|sqrt|log|exp|sin|cos)',o): return 'V:trans'
        if re.match(r'v_(perm|lshl_or|and_or|or3|bfe|bfi|alignbit|pack|lshrrev_b32|lshlrev|and_b32|or_b32|xor|cvt_pk)',o): return 'V:bit/pack'
        if re.match(r'v_(add_nc|add_co|sub_nc|subrev_nc|mul_lo|mul_hi|mad|add3|lshl_add|add_lshl|mad_u)',o): return 'V:int/addr'
        if o.startswith(('v_mov','v_readlane','v_writelane','v_readfirstlane','v_movrel','v_swap')): return 'V:mov'
        return 'V:other'
    return 'other'
for p in sys.argv[1:]:
    o=ops(p);c=collections.Counter(fam(x) for x in o)
    print(p,len(o),dict(sorted(c.items())))
