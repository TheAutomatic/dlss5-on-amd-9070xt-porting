import subprocess,sys,json,re,msgpack,struct
def meta(path):
    # parse NT_AMDGPU_METADATA note via llvm-readelf --notes is text; use raw ELF parsing
    b=open(path,'rb').read()
    shoff=struct.unpack_from('<Q',b,0x28)[0];shentsize,shnum=struct.unpack_from('<HH',b,0x3a)
    for i in range(shnum):
        o=shoff+i*shentsize;typ=struct.unpack_from('<I',b,o+4)[0]
        if typ==7:
            off,size=struct.unpack_from('<QQ',b,o+0x18);p=off
            while p<off+size:
                nsz,dsz,t=struct.unpack_from('<III',b,p);p+=12;name=b[p:p+nsz];p+=(nsz+3)&~3;desc=b[p:p+dsz];p+=(dsz+3)&~3
                if t==32: return msgpack.unpackb(desc,raw=False)
m={k['.symbol'][:-3] if k['.symbol'].endswith('.kd') else k['.symbol']:k for k in meta(sys.argv[1])['amdhsa.kernels']}
json.dump({s:{'kernarg':v['.kernarg_segment_size'],'args':[(a.get('.offset'),a.get('.size'),a.get('.value_kind')) for a in v.get('.args',[])],'vgpr':v.get('.vgpr_count'),'lds':v.get('.group_segment_fixed_size')} for s,v in m.items()},open(sys.argv[2],'w'))
