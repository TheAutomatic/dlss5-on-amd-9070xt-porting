#!/usr/bin/env python3
"""Instruction classes and opcode histograms for gfx12 ISA listings.

  isa_stats.py aco <file.s>                 one ACO pipeline (RADV executable 'Assembly')
  isa_stats.py llvm <file.hsaco.s> [kernel] LLVM/COMGR listing; per kernel, or the one named
  add --ops N to print the top-N VALU opcodes
"""
import collections, re, sys

def classify(op):
    if op.startswith('v_wmma') or op.startswith('v_swmmac'): return 'WMMA'
    if op.startswith('v_dual_'): return 'VOPD'
    if op.startswith(('ds_',)): return 'DS'
    if op.startswith(('global_', 'buffer_', 'flat_', 'scratch_', 'image_', 'tbuffer_')): return 'VMEM'
    if op.startswith(('s_load', 's_buffer_load', 's_prefetch')): return 'SMEM'
    if op.startswith(('s_wait', 's_nop', 's_delay_alu', 's_clause', 's_barrier', 's_sleep')): return 'WAIT'
    if op.startswith('s_'): return 'SALU'
    if op.startswith('v_'): return 'VALU'
    return None

def ops_of(lines, aco=False):
    for l in lines:
        if aco:
            l = l.strip()
            if not l or l.startswith(('BB', '/*', 'ACO', 'After', 'Shader')): continue
            if ' = ' in l: l = l.split(' = ', 1)[1]
            op = l.split()[0]
            if '::' in l:  # VOPD pair printed as one line
                op = 'v_dual_' + op.replace('v_dual_', '')
            if classify(op): yield op, l
            continue
        l = l.split('//')[0].split(';')[0].strip()
        if not l or l.endswith(':') or l.startswith('.'): continue
        op = l.split()[0]
        if classify(op): yield op, l

def report(name, lines, top, aco=False):
    c = collections.Counter(); v = collections.Counter()
    for op, _ in ops_of(lines, aco):
        k = classify(op); c[k] += 1
        if k in ('VALU', 'VOPD'): v[op] += 1
    tot = sum(c.values())
    print(f"{name:52} total {tot:6} VALU {c['VALU']:6} VOPD {c['VOPD']:5} WMMA {c['WMMA']:5} DS {c['DS']:5} "
          f"VMEM {c['VMEM']:5} SALU {c['SALU']:5} SMEM {c['SMEM']:4} WAIT {c['WAIT']:5}")
    for op, n in v.most_common(top): print(f"      {n:6} {op}")

def llvm_kernels(text):
    cur, buf = None, []
    for l in text.splitlines():
        m = re.match(r'^([A-Za-z_][\w.]*):\s*(;.*)?$', l)
        if m and not m[1].startswith('.L'):
            if cur: yield cur, buf
            cur, buf = m[1], []
            continue
        if cur and l.strip().startswith('.Lfunc_end'):
            yield cur, buf; cur, buf = None, []
            continue
        if cur: buf.append(l)
    if cur: yield cur, buf

if __name__ == '__main__':
    args = sys.argv[1:]; top = 0
    if '--ops' in args: i = args.index('--ops'); top = int(args[i + 1]); del args[i:i + 2]
    kind, path = args[0], args[1]
    text = open(path, errors='replace').read()
    if kind == 'aco': report(path.split('/')[-1], text.splitlines(), top, True)
    else:
        want = args[2] if len(args) > 2 else None
        for k, body in llvm_kernels(text):
            if want is None or k == want: report(k, body, top)
