exec(open('/tmp/daniel-kernels/dispatch/hostmap.py').read().split('lines=')[0])
strs={}
for m in re.finditer(rb'[ -~]{5,}\x00',b):
 for lo,hi,off in secs:
  if lo<=m.start()<hi:strs[m.start()+off]=m[0][:-1].decode();break
lines=pathlib.Path('/tmp/fma-vs-nvidia/daniel-host.s').read_text().splitlines()
for i,l in enumerate(lines):
 for h in re.findall(r'# (0x[0-9a-f]+)',l):
  s=strs.get(int(h,16),'')
  if any(x in s.lower() for x in ['chain','regkernel','reference','swin','quality','vit_','reg_','rdna']):
   print(i+1,l,s)
