"""Conservative same-basic-block conversion def/use; no matching by visual adjacency alone."""
import re

def analyze(lines):
 half={};floating={};pairs=[];nested=[];stores=[];versions={};memory={}
 def reg(s):
  m=re.fullmatch(r'v(\d+)',s.strip());return int(m[1]) if m else None
 def defs(s):
  if (r:=reg(s)) is not None:return [r]
  m=re.fullmatch(r'v\[(\d+):(\d+)\]',s.strip());return list(range(int(m[1]),int(m[2])+1)) if m else []
 for index,line in enumerate(lines):
  line=line.split('//')[0].split(';')[0].strip()
  if not line:continue
  if line.endswith(':'):half.clear();floating.clear();memory.clear();continue
  if line.startswith(('.', '#')):continue
  for item in line.split('::'):
   parts=item.strip().split(None,1)
   if len(parts)!=2:continue
   op=re.sub(r'_e(?:32|64)$','',parts[0]);args=[x.strip().split()[0] for x in parts[1].split(',')]
   dst=reg(args[0]);src=reg(args[1]) if len(args)>1 else None
   oldhalf=half.get(src);oldfloat=floating.get(src)
   if op.startswith('ds_store_b16') and len(args)>1 and oldhalf:
    stores.append({'store':index,'narrow':oldhalf[0]['narrow']});addr=(args[0],versions.get(reg(args[0]),0),re.search(r'offset:(\d+)',item).group(1) if 'offset:' in item else '0');memory[addr]=[oldhalf[0]]
   written=defs(args[0]) if op.startswith(('v_', 'ds_load', 'global_load', 'buffer_load','flat_load')) else []
   for d in written:half.pop(d,None);floating.pop(d,None);versions[d]=versions.get(d,0)+1
   if dst is None:continue
   if op=='v_cvt_f16_f32':
    origin={'narrow':index,'mode':'RNE','half_grid_input':oldfloat is not None};half[dst]=[origin]
    if oldfloat is not None:nested.append({'narrow':index,'prior_widen':oldfloat})
   elif op=='v_cvt_pkrtz_f16_f32':
    half[dst]=[{'narrow':index,'mode':'RTZ','half_grid_input':oldfloat is not None},{'narrow':index,'mode':'RTZ','half_grid_input':reg(args[2]) in floating}]
   elif op=='v_cvt_f32_f16':
    part=1 if 'src0_sel:WORD_1' in item or 'op_sel:[1' in item else 0
    if oldhalf and len(oldhalf)>part:pairs.append(dict(oldhalf[part],widen=index))
    floating[dst]=index
   elif op.startswith('v_mov_b32'):
    if oldhalf:half[dst]=oldhalf
    if oldfloat is not None:floating[dst]=oldfloat
   elif op.startswith('v_lshrrev_b32') and len(args)>2 and args[1] in ('16','0x10'):
    source=half.get(reg(args[2]));
    if source and len(source)>1:half[dst]=[source[1]]
   elif op.startswith('ds_load_u16'):
    addr=(args[1],versions.get(src,0),re.search(r'offset:(\d+)',item).group(1) if 'offset:' in item else '0')
    if addr in memory:half[dst]=memory[addr]
 return {'same_block_roundtrips':pairs,'half_grid_renarrowings':nested,'narrow_to_lds':stores}
