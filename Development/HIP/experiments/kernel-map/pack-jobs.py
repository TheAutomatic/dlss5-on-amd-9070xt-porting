#!/usr/bin/env python3
from pathlib import Path
import json,struct,argparse
p=argparse.ArgumentParser();p.add_argument('json',type=Path);p.add_argument('out',type=Path);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
for j in json.loads(a.json.read_text()):
 out=bytearray(struct.pack('<I',0x31304d4b))
 def add(fmt,*v):out.extend(struct.pack('<'+fmt,*v))
 def string(s):b=s.encode();add('I',len(b));out.extend(b)
 string(j['id']);string(j.get('module_file','daniel-gfx1201.hsaco' if j['module']=='daniel' else j['module']));string(j['symbol']);add('6I',*j['grid'],*j['block']);add('I',len(j['buffers']))
 for b in j['buffers']:
  string(b['id']);add('Q',b['bytes']);string(b['init']);add('d',b.get('amplitude',b.get('value',.25)));string(b.get('file',''));string(b.get('check','none'));add('Q',b.get('check_bytes',b['bytes']));segs=b.get('segments',[]).copy()
  for s in b.get('patches',[]):
   typ=s['type'];fmt={'f32':'f','u32':'I','i32':'i','u64':'Q','u16':'H','u8':'B'}[typ];data=struct.pack('<'+fmt,s['value'])*s.get('count',1)
   segs.extend(dict(offset=s['offset']+i,bytes=1,init='byte',value=v) for i,v in enumerate(data))
  add('I',len(segs))
  for s in segs:add('QQ',s['offset'],s['bytes']);string(s['init']);add('d',s.get('amplitude',s.get('value',.25)))
 args=bytearray(j['arg_bytes']);patch=[];indices={b['id']:i for i,b in enumerate(j['buffers'])}
 for v in j['args']:
  off=v['offset'];typ=v['type']
  if off>=len(args):raise ValueError((j['id'],'argument outside prefix',v))
  if typ=='ptr':
   if v.get('buffer') is not None:patch.append((off,indices[v['buffer']],v.get('buffer_offset',0)))
  else:
   fmt={'f32':'f','u32':'I','i32':'i','u64':'Q','u16':'H','u8':'B'}[typ];struct.pack_into('<'+fmt,args,off,v['value'])
 add('I',len(args));out.extend(args);add('I',len(patch))
 for x in patch:add('IIQ',*x)
 (a.out/(j['id']+'.bin')).write_bytes(out)
print('packed',len(json.loads(a.json.read_text())))
