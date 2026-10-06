from collections import Counter
import json

def rects(w,h,shift):
 sx=4 if shift&1 else 0;sy=4 if shift&2 else 0
 ww=(w+sx+7)&~7;hh=(h+sy+7)&~7
 return [(max(0,x*8-sx),max(0,y*8-sy),min(w,x*8-sx+8),min(h,y*8-sy+8)) for y in range(hh//8) for x in range(ww//8)]

def check(w,h):
 shifts=[3,1,2,0,3,1];layers=[rects(w,h,s) for s in shifts];degrees=[]
 for layer in layers:
  cover=Counter((x,y) for x0,y0,x1,y1 in layer for y in range(y0,y1) for x in range(x0,x1));assert len(cover)==w*h and set(cover.values())=={1};assert all(a<c and b<d for a,b,c,d in layer)
 for li,(a,b) in enumerate(zip(layers,layers[1:])):
  ins=[[] for _ in b];outs=[]
  for i,(x0,y0,x1,y1) in enumerate(a):
   children=[]
   for j,(u0,v0,u1,v1) in enumerate(b):
    if max(x0,u0)<min(x1,u1) and max(y0,v0)<min(y1,v1):children.append(j);ins[j].append(i)
   sx=4 if shifts[li+1]&1 else 0;sy=4 if shifts[li+1]&2 else 0;bw=((w+sx+7)&~7)//8
   native=[yy*bw+xx for yy in range((y0+sy)//8,(y1-1+sy)//8+1) for xx in range((x0+sx)//8,(x1-1+sx)//8+1)]
   assert native==children, (li,i,native,children)
   assert 1<=len(children)<=4;outs.append(len(children))
  assert all(1<=len(v)<=4 for v in ins)
  for j,parents in enumerate(ins):
   u0,v0,u1,v1=b[j];cov={(x,y) for i in parents for x0,y0,x1,y1 in [a[i]] for y in range(max(y0,v0),min(y1,v1)) for x in range(max(x0,u0),min(x1,u1))};assert len(cov)==(u1-u0)*(v1-v0)
  degrees.append({'parents':dict(Counter(map(len,ins))),'children':dict(Counter(outs))})
 return {'raster':[w,h],'shifts':shifts,'nodes_per_layer':list(map(len,layers)),'total':sum(map(len,layers)),'initial':len(layers[0]),'pixel_partition_and_read_dependency_coverage':'PASS','production_child_formula_matches_intersection_oracle':'PASS','edge_degrees':degrees}
print(json.dumps([check(100,60),check(120,72),check(160,92)],indent=2))
