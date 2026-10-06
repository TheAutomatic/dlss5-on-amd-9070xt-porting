import sys,re,subprocess,collections
B='/home/lmxxf/work/llvm-build-dlss5-gfx12/bin/'
K='c512_qkv_attention_compact'
for f in sys.argv[1:]:
    notes=subprocess.run([B+'llvm-readobj','--notes',f],capture_output=True,text=True).stdout
    i=notes.find('.name:           '+K)
    blk=notes[notes.rfind('- .agpr',0,i) if notes.rfind('- .agpr',0,i)>=0 else 0: i+2000]
    def g(k):
        m=re.findall(r'\.'+k+r':\s+(\d+)',blk);return m[-1] if m else '?'
    s=open(f.replace('.hsaco','.s')).read().splitlines()
    ins=[l.split()[0] for l in s if l.startswith('\t') or l.startswith(' ') and l.strip()]
    ins=[l.strip().split() for l in s if l.strip() and not l.strip().endswith(':') and not l.startswith('Disass') and '<' not in l and 'file format' not in l]
    # QKV region = up to first ds_store (packed write)
    end=next(i for i,x in enumerate(ins) if x[0].startswith('ds_store'))
    q=ins[:end]
    ld=[i for i,x in enumerate(q) if x[0].startswith('global_load')]
    wm=[i for i,x in enumerate(q) if 'wmma' in x[0]]
    waits=[int(x[1].rstrip(','),0) for x in q if x[0]=='s_wait_loadcnt']
    br=sum(1 for x in q if x[0].startswith('s_cbranch'))
    # max outstanding: simulate issue count minus waits
    out=0;mx=0;hist=[]
    for x in q:
        if x[0].startswith('global_load'): out+=1;mx=max(mx,out)
        elif x[0]=='s_wait_loadcnt': out=min(out,int(x[1],0)); hist.append(out)
    imm=sum(1 for x in q if x[0].startswith('global_load') and 'offset:' in ' '.join(x))
    print(f"{f}: vgpr={g('vgpr_count')} sgpr={g('sgpr_count')} lds={g('group_segment_fixed_size')} priv={g('private_segment_fixed_size')} | QKV: loads={len(ld)} imm_off={imm} wmma={len(wm)} waits={len(waits)} branches={br} max_in_flight={mx} wait_imm_hist={collections.Counter(waits).most_common(8)}")
