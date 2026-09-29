from pathlib import Path
import json,struct
r=Path('/tmp/kernel-map');raw=json.loads((r/'ours-record.json').read_text());types=json.loads((r/'ours-types.json').read_text());meta=json.loads((r/'ours-metadata.json').read_text())
modules={'c32_wave1':'c32-wave1','c64_wave2':'c64-wave2','c512_m32_mh':'c512-m32-mh','c512_m32_deep':'c512-m32-deep','deep_fast':'deep_fast-packed','deep':'deep_reference','mh':'multihead-reference','mh_fast':'multihead-fast-padded-wave-packed','vit_stream':'vit-stream'}
jobs=[];(r/'synthetic').mkdir(exist_ok=True)
for j in raw:
 k=j['symbol'];t=types[k];file=modules[j['module']]+'.hsaco';m=meta[file+':'+k];nargs=[a for a in m['.args'] if not a['.value_kind'].startswith('hidden')];actual=max(a['.offset']+a['.size'] for a in nargs)
 args=[];bufs={}
 for i,a in enumerate(j['args']):
  if a['offset']>=actual:continue
  if a['type']!='ptr':args.append(a);continue
  if not a['value']:args.append({'offset':a['offset'],'type':'ptr','value':0});continue
  key=a['value'];bid='b'+str(list(bufs).index(key)) if key in bufs else 'b'+str(len(bufs));isout=str(i) in t['output_types'];isin=str(i) in t['input_types'];dtype=t['input_types'].get(str(i),'zero');check=t['output_types'].get(str(i),'none')
  if key not in bufs:
   b=dict(id=bid,bytes=a['bytes'],init=dtype,value=.25,check=check,check_bytes=a['bytes']);bufs[key]=b
   if a['file']:b.update(init='file',file='synthetic/'+a['file'])
   elif k=='vit_gather' and i==1:
    N=a['bytes']//4;tokens=N//1024;inverse=sum(x['symbol']=='vit_gather' for x in jobs)>0;arr=[0]*N
    for token in range(tokens):
     for c in range(1024):
      raster=(token&~15)|((token&1)<<3)|((token&14)>>1);ch=(c&~31)|((c&1)<<1)|((c&2)>>1)|((c&4)<<2)|((c&24)>>1);to=token*1024+c;fr=raster*1024+ch
      if inverse:arr[fr]=to
      else:arr[to]=fr
    fname=f'gather-{int(inverse)}.bin';(r/'synthetic'/fname).write_bytes(struct.pack('<'+'I'*N,*arr));b.update(init='file',file='synthetic/'+fname)
   else:assert isin or isout,(j['id'],k,i,a)
  elif isout:bufs[key]['check']=check
  args.append(dict(offset=a['offset'],type='ptr',buffer=bid))
 jobs.append(dict(id=j['id'],module=j['module'],module_file='flat-A/'+file,symbol=k,grid=j['grid'],block=j['block'],arg_bytes=actual,buffers=list(bufs.values()),args=args,notes=t['special']))
(r/'ours-jobs.json').write_text(json.dumps(jobs,indent=2)+'\n');print(len(jobs),'ours jobs')
