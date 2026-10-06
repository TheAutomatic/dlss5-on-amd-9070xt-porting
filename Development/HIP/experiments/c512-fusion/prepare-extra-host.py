#!/usr/bin/env python3
"""Prepare the independently tested M32 or wave16 host on the pinned F snapshot."""
from pathlib import Path
import argparse,subprocess,sys
ap=argparse.ArgumentParser();ap.add_argument('mode',choices=['M','W']);ap.add_argument('out',type=Path);a=ap.parse_args()
subprocess.run([sys.executable,str(Path(__file__).with_name('prepare-runner.py')),str(a.out)],check=True)
p=a.out/'Development/HIP/hip_reference_network.h';s=p.read_text();s='#ifndef C512_T8_M32_HOST\n#define C512_T8_M32_HOST 0\n#endif\n'+s
anchor='   if(kernel=="vit_ffn_fused"){threads=512;groups=count/16384;}'
assert s.count(anchor)==1;s=s.replace(anchor,'#if C512_T8_M32_HOST\n   if(kernel=="split_ffn_fused_fp8_t8"){threads=128;groups=((count/512+31)/32)*8;}\n#endif\n'+anchor)
if a.mode=='W':
 s='#ifndef C256_WAVE16_EXPERIMENT\n#define C256_WAVE16_EXPERIMENT 0\n#endif\n'+s
 old='if(wave_owned_active&&(c==64||c==128||(c==256&&opt.width==1920&&opt.height==1152)))';assert s.count(old)==1
 s=s.replace(old,'if(wave_owned_active&&(c==64||c==128||(c==256&&opt.width==1920&&opt.height==1152)||(C256_WAVE16_EXPERIMENT&&c==256&&opt.width==1600&&opt.height==960)))')
 anchor='  Run("c64_wave2",name.c_str(),n/64,';assert s.count(anchor)==1
 s=s.replace(anchor,'  if(C256_WAVE16_EXPERIMENT&&c==256&&opt.width==1600&&opt.height==960)name="c256_wave16"+std::string(byte_in?"_bi":"")+(byte_out?"_bo":"");\n'+anchor)
 old='if(module=="c64_wave2"){groups=count;threads=kernel.rfind("c64_",0)==0?64:kernel.rfind("c128_",0)==0?128:256;}';assert s.count(old)==1
 s=s.replace(old,'if(module=="c64_wave2"){groups=count;threads=kernel.rfind("c256_wave16",0)==0?512:kernel.rfind("c64_",0)==0?64:kernel.rfind("c128_",0)==0?128:256;}')
p.write_text(s)
