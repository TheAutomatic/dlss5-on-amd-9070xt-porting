#!/usr/bin/env python3
"""HIP-only roofline for the DLSS5 network on RX 9070 XT (2026-09-30).
Analytic model, refreshed from results/9070-theoretical-20260921/estimate.py (same block list, window padding,
shift padding, 1152-row 1080 geometry, ViT 400/640 tokens). 2 FLOP per MAC.
Adds: minimal VALU lane-op model, minimal DRAM bytes (weights once + block-boundary activations in current formats).
Everything here is a model, not a hardware counter (Windows, no counters)."""
import json,sys
from pathlib import Path
CLK=float(sys.argv[1]) if len(sys.argv)>1 else 2.75e9      # in-network core clock (clock-ledger-20260924: 2.75 GHz @1080, ~2.80 @900)
SPEC_CLK=2.97e9; FP8_SPEC=389e12; F16_SPEC=195e12             # AMD spec: dense FP8 389 TFLOPS, FP16 195 at 2.97 GHz boost, 64 CU
FP8_PEAK=FP8_SPEC*CLK/SPEC_CLK; F16_PEAK=F16_SPEC*CLK/SPEC_CLK
VALU_RATE=64*2*32*CLK       # lane-ops/s: 64 CU x 2 SIMD32 x 32 lanes x 1 instr/clk (no VOPD dual issue assumed)
out={}
shifts=[0,3,1,2,0,3,1,2];dec=[0,3,1,2,0,3,1,2,0,3,1,2,0,3,1,2,1,2,0,3,1,2,0,3,1,2,0,3,1,2]
for tier,W,H,n in [(900,1600,960,400),(1080,1920,1152,640)]:
 fl={};wb={};ab={};valu={}
 def F(name,mac,p='fp8'):fl[name+'/'+p]=fl.get(name+'/'+p,0)+2*mac
 def WB(name,params,bytes_per):wb[name]=wb.get(name,0)+params*bytes_per
 def AB(name,b):ab[name]=ab.get(name,0)+b
 def V(name,ops):valu[name]=valu.get(name,0)+ops
 def block(b,c,w,h,shift):
  if b in [42,43,46]:return                          # skipped blocks (production)
  sx=4 if shift&1 else 0;sy=4 if shift&2 else 0
  t=(w+2*sx)*(h+2*sy) if c==32 else ((w+sx+7)//8*8)*((h+sy+7)//8*8)   # padded tokens actually computed
  real=w*h
  fam='C32' if c==32 else f'C{c}'
  if c==32:F(fam,t*(12*c*c+128*c));WB(fam,12*c*c,1)
  elif c<512:F(fam,t*(9*c*c+256*c));WB(fam,9*c*c+128*c,1)
  else:
   F(fam,t*(512*512+8*64*256),'fp16');F(fam,t*(8*256*64+512*512+3*512*512+512*512+128*512))
   WB(fam,512*512+8*64*256,2);WB(fam,8*256*64+5*512*512,1)
  AB(fam,2*real*c)                                   # block input read + output write, E4M3 1 B/elem
  heads=c//32; scores=t*64*heads
  # minimal VALU lane-ops: requant every matmul output to FP8 (~3), softmax per score (~5), activation on 4C hidden (~6), norm+residual per elem (~5)
  mm_out=t*c*(3+1+1+1)+t*4*c                         # qkv(3C)+proj(C)+contract(C)+misc(C) + hidden(4C)
  V(fam,mm_out*3+scores*5+t*4*c*6+t*c*5)
 block(0,32,W,H,0);block(70,32,W,H,3)
 for b in range(1,5):block(b,32,W//2,H//2,shifts[b-1])
 for c,start,end,div in [(64,5,9,4),(128,9,15,8),(256,15,23,16),(512,23,31,32)]:
  for b in range(start,end):block(b,c,W//div,H//div,shifts[b-start])
 for c,start,end,div in [(512,40,48,32),(256,48,56,16),(128,56,62,8),(64,62,66,4),(32,66,70,2)]:
  for b in range(start,end):block(b,c,W//div,H//div,dec[b-40])
 # skip connections: each encoder level output read once more by the decoder (E4M3)
 for c,div in [(32,2),(64,4),(128,8),(256,16),(512,32)]:AB('skip',(W//div)*(H//div)*c)
 AB('skip',W*H*32)                                   # full-raster C32 skip (prefix main -> post)
 # ViT (8 layers, 1024 wide, n tokens)
 F('ViT',8*n*(2*1024*4096+1024*1024));F('ViT',8*n*3*1024*1024,'fp16');F('ViT-attn',8*2*n*n*1024)
 WB('ViT',8*(2*1024*4096+1024*1024),1);WB('ViT',8*3*1024*1024,2)
 AB('ViT',8*2*n*1024*2)                              # layer in/out, half
 V('ViT',8*(n*1024*(3+1+1)*3+n*n*16*5+n*4096*6+n*1024*5))
 F('input-head',W*H*16*32,'fp16');WB('head',16*32,2)
 for c,div in [(32,4),(64,8),(128,16),(256,32)]:F('down',W//div*(H//div)*c*(2*c),'fp16');WB('down',c*2*c,2)
 F('down',n*512*1024,'fp16');F('up',n*1024*512,'fp16');WB('down',512*1024,2);WB('up',1024*512,2)
 for ic,oc,div in [(512,256,32),(256,128,16),(128,64,8),(64,32,4)]:F('up',W//div*(H//div)*ic*oc,'fp16');WB('up',ic*oc,2)
 F('RGB',W*H*32*3,'fp32')
 AB('io',W*H*16+W*H*16+W*H*12)                       # rgba f32x4 in (prefix), color f32x4 again (post residual), rgb f32x3 out
 AB('io-copy',2*W*H*12)                              # HIP output hipMemcpy D2D (read+write)
 f8=sum(v for k,v in fl.items() if k.endswith('/fp8'));f16=sum(v for k,v in fl.items() if k.endswith('/fp16'));f32=sum(v for k,v in fl.items() if k.endswith('/fp32'))
 comp_ms=(f8/FP8_PEAK+f16/F16_PEAK+f32/(48.7e12*CLK/SPEC_CLK))*1e3
 vops=sum(valu.values());valu_ms=vops/VALU_RATE*1e3
 wbytes=sum(wb.values());abytes=sum(v for k,v in ab.items() if k!='io-copy')
 out[tier]=dict(GFLOP={k:round(v/1e9,2) for k,v in sorted(fl.items())},fp8_GFLOP=f8/1e9,fp16_GFLOP=f16/1e9,fp32_GFLOP=f32/1e9,
  compute_floor_ms=comp_ms,valu_Glaneops=vops/1e9,valu_floor_ms=valu_ms,valu_by_family_ms={k:round(v/VALU_RATE*1e3,4) for k,v in valu.items()},
  weight_MB=wbytes/1e6,weight_MB_by_family={k:round(v/1e6,2) for k,v in wb.items()},act_MB=abytes/1e6,act_MB_by_family={k:round(v/1e6,2) for k,v in ab.items()},
  clock_GHz=CLK/1e9,fp8_peak_TFLOPS=FP8_PEAK/1e12,f16_peak_TFLOPS=F16_PEAK/1e12,valu_Tlaneops=VALU_RATE/1e12)
Path(__file__).with_name('roofline.json').write_text(json.dumps(out,indent=1)+'\n');print(json.dumps(out,indent=1))
