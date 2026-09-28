import struct,re,json,pathlib
D=pathlib.Path('/tmp/claude-1000/-home-lmxxf-work-ai-theorys-study/129f068a-8529-42b4-b98b-08071124e161/scratchpad/d050')
b=(D/'x/mod.dll').read_bytes();pe=struct.unpack_from('<I',b,60)[0];n=struct.unpack_from('<H',b,pe+6)[0];op=struct.unpack_from('<H',b,pe+20)[0];secs=[]
for i in range(n):
 s=pe+24+op+i*40; vs,va,rs,ro=struct.unpack_from('<IIII',b,s+8);secs.append((ro,ro+rs,0x180000000+va-ro))
names={}
for m in re.finditer(rb'_Z[A-Za-z0-9_]+\x00',b):
 for lo,hi,off in secs:
  if lo<=m.start()<hi:names[m.start()+off]=m[0][:-1].decode();break
lines=pathlib.Path('/tmp/fma-vs-nvidia/daniel-host.s').read_text().splitlines();out=[]
for i,l in enumerate(lines):
 for h in re.findall(r'0x[0-9a-f]+',l):
  if int(h,16) in names:
   out.append({'line':i+1,'address':l.split(':')[0],'symbol':names[int(h,16)],'context':lines[max(0,i-3):i+7]})
pathlib.Path('/tmp/daniel-kernels/dispatch/host-symbol-refs.json').write_text(json.dumps(out,indent=2))
print('names',len(names),'refs',len(out))
stubs={}
for r in out:
 for l in r['context'][:3]:
  m=re.search(r'leaq.*%rdx.*# (0x[0-9a-f]+)',l)
  if m:stubs[int(m[1],16)]=r['symbol']
refs=[]
for i,l in enumerate(lines):
 for h in re.findall(r'# (0x[0-9a-f]+)',l):
  if not re.match(r"[0-9a-f]+:",l):continue
  a=int(l.split(':')[0],16)
  if int(h,16) in stubs and not 0x180025000<=a<=0x180028000:
   refs.append({'line':i+1,'address':hex(a),'symbol':stubs[int(h,16)],'context':lines[max(0,i-14):i+10]})
pathlib.Path('/tmp/daniel-kernels/dispatch/host-launch-refs.json').write_text(json.dumps(refs,indent=2))
print('stub refs',len(refs))
for r in refs:print(r['address'],r['symbol'])
