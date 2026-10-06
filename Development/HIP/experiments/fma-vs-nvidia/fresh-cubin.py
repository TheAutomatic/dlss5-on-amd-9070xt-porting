#!/usr/bin/env python3
from pathlib import Path
import os,sys,subprocess,json,hashlib
import numpy as np
ROOT=Path(__file__).resolve().parents[4];OUT=Path(sys.argv[1]) if len(sys.argv)>1 else Path('/tmp/fma-vs-nvidia/oracle-fresh');OUT.mkdir(parents=True,exist_ok=True)
os.chdir(ROOT);sys.path.insert(0,str(ROOT/'Development'))
from encode_tinlayout_global import quantize
from decode_tinlayout_global import e4m3fn
x=np.fromfile(ROOT/'release/native-c32/amd-block1/input.f32',np.float32).reshape(4,8,8,8,32).transpose(0,2,1,3,4).reshape(32,64,32)
# Invert the reference export: 8x8 tiles -> HWC -> two planar C16 slabs.
raw=quantize(x.reshape(32,64,2,16).transpose(2,0,1,3)).ravel();raw.tofile(OUT/'reconstructed-plain-input.fp8')
assert np.array_equal(e4m3fn(raw).reshape(2,32,64,16).transpose(1,2,0,3).reshape(x.shape),x)
compile_cmd=['c++','-O2','-I/usr/local/cuda/include','Development/run_original_fused_global.cpp','-lcuda','-o',str(OUT/'original-caller')]
subprocess.run(compile_cmd,check=True)
cmd=[str(OUT/'original-caller'),'/tmp/fma-vs-nvidia/cubins/dlssnr-00.cubin','release/native-c32/block1.weights',str(OUT/'reconstructed-plain-input.fp8'),str(OUT/'fresh-main.fp8'),str(OUT/'fresh-aux.fp8'),'cc_tinlayout_fused_swin_1h_32_1_fp8','64','32','8','4','1','4','0']
p=subprocess.run(cmd,text=True,capture_output=True);(OUT/'fresh-cubin.log').write_text(p.stdout+p.stderr);p.check_returncode()
a=np.fromfile(OUT/'fresh-main.fp8',np.uint8);b=np.fromfile(ROOT/'release/native-c32/block1-output.fp8',np.uint8)
# The exported float oracle uses inpview output physical cells, not ordinary output.
inp_cmd=cmd.copy();inp_cmd[4]=str(OUT/'fresh-inpview-main.fp8');inp_cmd[5]=str(OUT/'fresh-inpview-aux.fp8');inp_cmd[6]='cc_tinlayout_fused_swin_1h_32_1_inpview_fp8';inp_cmd[12]='5'
run=subprocess.run(inp_cmd,text=True,capture_output=True);(OUT/'fresh-inpview-cubin.log').write_text(run.stdout+run.stderr);run.check_returncode()
inp=np.fromfile(OUT/'fresh-inpview-main.fp8',np.uint8);oldinp=np.fromfile(ROOT/'release/native-c32/block1-inpview-output.fp8',np.uint8)
sm=np.fromfile(ROOT/'release/post-skip-basis/matrix.f32','<f4').reshape(2048,2048);cm=np.argmax(np.abs(sm),axis=0).reshape(8,8,32)[:4,:4]
y=e4m3fn(inp[:65536].reshape(-1,512)[:,cm]).reshape(8,16,4,4,32).transpose(0,2,1,3,4).reshape(32,64,32)
z=np.fromfile(ROOT/'release/native-c32/amd-block1/oracle.f32',np.float32).reshape(y.shape)
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
res={'compile_command':compile_cmd,'launch_command':cmd,'input_layout':'8x8 tile float32 -> HWC -> 2 planar C16 slabs, exact FP8 decode roundtrip verified','output_layout':'VERIFIED: float oracle comes from inpview variant in 4x4 physical cells; mapped by post-skip-basis/matrix.f32 exactly as reference --output-cells','inpview_launch_command':inp_cmd,'inpview_raw_arena_different_bytes':int(np.count_nonzero(inp!=oldinp)),'raw_arena_bytes':a.size,'raw_arena_different_bytes':int(np.count_nonzero(a!=b)),'active_output_bytes':65536,'active_different_bytes':int(np.count_nonzero(a[:65536]!=b[:65536])),'decoded_vs_saved_float_oracle_different':int(np.count_nonzero(y!=z)),'decoded_vs_saved_float_oracle_mae':float(np.abs(y-z).mean()),'sha256':{str(p):sha(p) for p in [cmd[1],ROOT/'release/native-c32/block1.weights',OUT/'reconstructed-plain-input.fp8',OUT/'fresh-main.fp8',ROOT/'release/native-c32/block1-output.fp8']}}
(OUT/'fresh-cubin.json').write_text(json.dumps(res,indent=2));print(json.dumps(res,indent=2))
