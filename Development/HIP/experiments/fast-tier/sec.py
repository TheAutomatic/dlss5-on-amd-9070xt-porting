import struct,sys
def secs(f):
    d=open(f,'rb').read();shoff,=struct.unpack_from('<Q',d,0x28);shentsize,shnum,shstrndx=struct.unpack_from('<HHH',d,0x3A)
    sh=[struct.unpack_from('<IIQQQQIIQQ',d,shoff+i*shentsize) for i in range(shnum)]
    st=sh[shstrndx];name=lambda o:d[st[4]+o:d.index(b'\0',st[4]+o)].decode()
    return {name(s[0]):d[s[4]:s[4]+s[5]] for s in sh if name(s[0]) in('.text','.rodata','.note')}
for m in sys.argv[1:]:
    a,b=secs(f'p-{m}.hsaco'),secs(f'i-{m}.hsaco');print(m,{k:a[k]==b.get(k) for k in a})
