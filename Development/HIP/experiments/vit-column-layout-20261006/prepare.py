from pathlib import Path
import argparse,importlib.util,json,hashlib
p=argparse.ArgumentParser();p.add_argument('output',type=Path);a=p.parse_args();r=Path(__file__).resolve().parents[4]
sp=importlib.util.spec_from_file_location('recipe',r/'Development/tools/llvm-fork/compile-modules.py');m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m)
for stem,name in [('producer','vit-stream'),('consumer','deep_fast-packed-fast')]:
 row=next(x for x in m.recipe(r/'hip')if x[0]==name);s=row[2];d=a.output/stem;d.mkdir(parents=True,exist_ok=True)
 if stem=='producer':
  start=s.index('void vit_stream_qkv_frag_bin_w5f8(');part=s[start:]
  needle=' for(uint j=0;j<2;j++)for(uint e=0;e<8;e++){float v=acc[j][e];if(part<2){v*=__builtin_amdgcn_rsqf(maxf(sum[e],6.198883056640625e-5f))*scale;}out[(part*tokens+first+gr()*8+e)*1024+row+j*16+rc()]=byte_F(v);}'
  assert part.count(needle)==1
  repl=''' if(tokens==640){for(uint j=0;j<2;j++){i2 packed{};for(uint e=0;e<8;e++){float v=acc[j][e];if(part<2){v*=__builtin_amdgcn_rsqf(maxf(sum[e],6.198883056640625e-5f))*scale;}uint b=byte_F(v)&255u;packed[e/4]=int(uint(packed[e/4])|(b<<(8*(e%4))));}__builtin_memcpy(out+size_t(part)*tokens*1024+size_t(first)*1024+(row+j*16)*16+rc()*16+gr()*8,&packed,8);}}else{'''+needle+'}'
  new=s[:start]+part.replace(needle,repl)
 else:
  start=s.index('DEV void vit_attention_transposed_score_body');end=s.index('// FAST TIER',start);part=s[start:end]
  for var,plane,tok in [('q[k/16]',0,'first'),('y',1,'key')]:
   needle=f'if constexpr(ByteInput)__builtin_memcpy(&{var},in8+({"first" if plane==0 else "tokens+key"}+rc())*1024+head*32+k+gr()*8,8);'
   assert part.count(needle)==1
   repl=f'''if constexpr(MAXT==640&&ByteInput&&ByteOut){{if(tokens==640){{uint lane=__builtin_amdgcn_workitem_id_x(),rr=(lane/8)*4+(lane&3),cc=(lane&4)?8:0;using gi2=i2 __attribute__((address_space(1)));{var}=__builtin_amdgcn_global_load_tr_b64_v2i32((gi2*)(in8+size_t({plane})*tokens*1024+{tok}*1024+(head*32+k)*16+rr*16+cc));}}else __builtin_memcpy(&{var},in8+({"first" if plane==0 else "tokens+key"}+rc())*1024+head*32+k+gr()*8,8);}}else '''+needle
   part=part.replace(needle,repl)
  needle='for(uint c=0;c<2;c++){i2 y{};for(uint e=0;e<8;e++){uint vkey=key+gr()*8+e;if constexpr(ByteInput){uint b=in8[(2*tokens+vkey)*1024+head*32+c*16+rc()];y[e/4]=int(uint(y[e/4])|(b<<(8*(e%4))));}else pack(y,e,in[(2*tokens+vkey)*1024+head*32+c*16+rc()]);}'
  assert part.count(needle)==1
  repl='for(uint c=0;c<2;c++){i2 y{};if constexpr(MAXT==640&&ByteInput&&ByteOut){if(tokens==640)__builtin_memcpy(&y,in8+size_t(2)*tokens*1024+key*1024+(head*32+c*16)*16+rc()*16+gr()*8,8);else '+needle.split('i2 y{};')[1]+'}else '+needle.split('i2 y{};')[1]
  part=part.replace(needle,repl);new=s[:start]+part+s[end:]
 (d/'old.hip').write_text(s);(d/'new.hip').write_text(new);(d/'source.json').write_text(json.dumps({'row':name,'compiler':row[1]or'COMGR','opts':row[-1],'oldSHA':hashlib.sha256(s.encode()).hexdigest(),'newSHA':hashlib.sha256(new.encode()).hexdigest(),'scope':'pairedtokens640only; producerbinw5f8/consumer640byteinbout only; originalnumeric expressions retained'},indent=2))
