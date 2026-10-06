#!/usr/bin/env python3
import os,sys,json,inspect
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4];os.chdir(ROOT);sys.path.insert(0,str(ROOT/'Development'))
import numpy as np
import native_c32_reference as ref
from encode_tinlayout_global import quantize
OUT=Path(sys.argv[1]) if len(sys.argv)>1 else ROOT/'Development/results/fma-vs-nvidia-20260928/activation-recheck';OUT.mkdir(parents=True,exist_ok=True)
H=ref.H
# Inputs/products have far fewer than 53 significant bits here: double evaluates
# both half and float polynomial FMAs exactly before the single target rounding.
def fma(a,b,c):return (np.asarray(a,np.float64)*np.asarray(b,np.float64)+np.asarray(c,np.float64)).astype(np.float32)
def activation(a,mode):
 a=np.asarray(a,np.float32)
 if mode=='H':
  a=H(a);g=np.clip(a,-4,4);q=H(np.abs(g).astype(np.float64)*(-.055908203125)+.447265625);p=H(g.astype(np.float64)*q.astype(np.float64)+.89453125);return H(a*p)
 g=np.clip(a,-4,4)
 if mode=='A':q=np.abs(g)*np.float32(-.055908203125)+np.float32(.447265625);p=g*q+np.float32(.89453125)
 else:q=fma(np.abs(g),-.055908203125,.447265625);p=fma(g,q,.89453125)
 return a*p

def stat(a,b):
 a=np.asarray(a);b=np.asarray(b);d=np.abs(a.astype(np.float64)-b.astype(np.float64));return dict(count=a.size,different=int(np.count_nonzero(a!=b)),exact_fraction=float(np.mean(a==b)),nonfinite_error_count=int(np.count_nonzero(~np.isfinite(d))),mae=float(d.mean()) if np.isfinite(d).all() else None,max_error=float(d.max()) if np.isfinite(d).all() else None,finite_only_mae=float(d[np.isfinite(d)].mean()))
def probe(a):
 v={m:activation(a,m) for m in 'AFH'};q={m:quantize(v[m]) for m in v};return {'input_count':a.size,'raw':{x+':'+y:stat(v[x],v[y]) for x,y in [('A','H'),('F','H'),('A','F')]},'fp8_decoded':{x+':'+y:stat(ref.e4m3fn(q[x]),ref.e4m3fn(q[y])) for x,y in [('A','H'),('F','H'),('A','F')]},'fp8_changed_A_F_examples':[{'input':float(a.ravel()[i]),'A':float(v['A'].ravel()[i]),'F':float(v['F'].ravel()[i]),'H':float(v['H'].ravel()[i]),'byte_A':int(q['A'].ravel()[i]),'byte_F':int(q['F'].ravel()[i]),'byte_H':int(q['H'].ravel()[i])} for i in np.flatnonzero(q['A'].ravel()!=q['F'].ravel())[:20]]}
with np.errstate(over='ignore',invalid='ignore'):
 half=np.arange(65536,dtype=np.uint16).view(np.float16).astype(np.float32);half=half[np.isfinite(half)];res={'finite_half_sweep':probe(half)}
 lab=ROOT/'release/native-c32/amd-block1';tiles=np.fromfile(lab/'input.f32',np.float32).reshape(-1,64,32);w=ref.unpack(ROOT/'release/native-c32/block1.weights');expanded=ref.F(tiles)@w[0].T
 res['real_block1_expand_fp32']=probe(expanded);res['real_block1_expand_half']=probe(H(expanded))
 # Hold every later operation at the recovered NVIDIA reference semantics.
 # This isolates activation, and is NOT a complete current-AMD emulation.
 src=inspect.getsource(ref.block);start=src.index(' expanded=');end=src.index('proj=H(tiles*fs)',start)
 src=src[:start]+" expanded=F(tiles)@w1.T;hidden=F(activation(expanded,MODE));"+src[end:]
 oracle=np.fromfile(lab/'oracle.f32',np.float32).reshape(32,64,32);pred={}
 for mode in 'AFH':
  env=ref.__dict__.copy();env.update(activation=activation,MODE=mode);exec(src,env);p=env['block'](tiles,w).reshape(4,8,8,8,32).transpose(0,2,1,3,4).reshape(32,64,32);pred[mode]=p
 res['original_CUBIN_block1_oracle_controlled_activation']={m:stat(p,oracle) for m,p in pred.items()};res['block_pairwise']={a+':'+b:stat(pred[a],pred[b]) for a,b in [('A','F'),('A','H'),('F','H')]}
 res['provenance']={'input':str(lab/'input.f32'),'weights':str(ROOT/'release/native-c32/block1.weights'),'oracle':str(lab/'oracle.f32'),'warning':'Controlled activation substitution in recovered NVIDIA CPU reference; not full AMD/Daniel network comparison.'}
 res['original_reference_vs_H']=stat(ref.block(tiles,w).reshape(4,8,8,8,32).transpose(0,2,1,3,4).reshape(32,64,32),pred['H']);(OUT/'results.json').write_text(json.dumps(res,indent=2,allow_nan=False));print(json.dumps(res,indent=2))
