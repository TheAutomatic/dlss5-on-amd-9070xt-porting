#!/usr/bin/env python3
"""Print '<binding> <type>' lines (type: buf|cis|simg) for set 0 of a SPIR-V compute shader, via spirv-dis."""
import re, subprocess, sys
dis = subprocess.run(['spirv-dis', '--raw-id', sys.argv[1]], capture_output=True, text=True, check=True).stdout
binding, dset, var_type, ptr, types = {}, {}, {}, {}, {}
for line in dis.splitlines():
    m = re.match(r'\s*OpDecorate (%\d+) Binding (\d+)', line)
    if m: binding[m[1]] = int(m[2]); continue
    m = re.match(r'\s*OpDecorate (%\d+) DescriptorSet (\d+)', line)
    if m: dset[m[1]] = int(m[2]); continue
    m = re.match(r'\s*(%\d+) = OpTypePointer (\w+) (%\d+)', line)
    if m: ptr[m[1]] = (m[2], m[3]); continue
    m = re.match(r'\s*(%\d+) = OpVariable (%\d+) (\w+)', line)
    if m: var_type[m[1]] = m[2]; continue
    m = re.match(r'\s*(%\d+) = (OpType\w+)(.*)', line)
    if m: types[m[1]] = (m[2], m[3].split())
out = {}
for v, b in binding.items():
    if dset.get(v, 0) != 0: continue
    sc, pointee = ptr[var_type[v]]
    if sc == 'StorageBuffer': t = 'buf'
    elif sc == 'UniformConstant':
        k, args = types[pointee]
        while k == 'OpTypeArray' or k == 'OpTypeRuntimeArray': k, args = types[args[0]]
        if k == 'OpTypeSampledImage': t = 'cis'
        elif k == 'OpTypeImage': t = 'simg' if args[-2] == '2' else 'simgs'
        else: t = 'unk:' + k
    elif sc == 'Uniform': t = 'ubo'
    else: t = 'unk:' + sc
    if b in out and out[b] != t: sys.exit(f'binding {b} type conflict {out[b]} vs {t}')
    out[b] = t
for b in sorted(out): print(b, out[b])
