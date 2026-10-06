"""Independent natural-key tree and physical permuted representation check, finite domain."""
from pathlib import Path
import numpy as np,json
r=Path(__file__).resolve().parents[3]/'results/vit-math-contract-20261006'
p=np.fromfile(r/'probability-8x640.f16','<f2').reshape(8,640)
h=lambda x:np.asarray(x,dtype=np.float16)
perm=np.array([0,1,2,3,8,9,10,11,4,5,6,7,12,13,14,15]);total=np.zeros(8,np.float16);actual=total.copy();prefix=[];rep=[]
for chunk in range(10):
 a=np.zeros((8,8),np.float16);part=np.zeros((8,2,4),np.float16)
 for tile in range(4):
  natural=p[:,chunk*64+tile*16:chunk*64+tile*16+16];paired=h(natural[:,:8]+natural[:,8:]);a=paired if tile==0 else h(a+paired)
  physical=natural[:,perm].reshape(8,2,8);local=h(physical[:,:,:4]+physical[:,:,4:]);part=local if tile==0 else h(part+local)
  restored=physical.reshape(8,16)[:,perm]
  assert np.array_equal(restored.view('u2'),natural.view('u2'))
 even=a[:,0];odd=a[:,1]
 for j in [2,4,6]:even=h(even+a[:,j]);odd=h(odd+a[:,j+1])
 total=h(total+h(even+odd));prefix.append(total.copy())
 ordered=part.reshape(8,8);s=ordered[:,:2]
 for j in [2,4,6]:s=h(s+ordered[:,j:j+2])
 actual=h(actual+h(s[:,0]+s[:,1]));rep.append(actual.copy())
assert np.array_equal(np.array(prefix).view('u2'),np.array(rep).view('u2'))
print(json.dumps({'prefix_half_code_diff':0,'P_natural_code_diff':0,'rows':8,'chunks':10,'scope':'finite half tree and physical permutation; no WMMA hardware equivalence claim'}))
