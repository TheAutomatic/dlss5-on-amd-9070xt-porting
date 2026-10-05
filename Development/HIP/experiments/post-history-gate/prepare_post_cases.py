from pathlib import Path
import argparse,json,shutil,numpy as np
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);p.add_argument('--source-root',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
n=16;np.zeros(73728,np.uint8).tofile(a.output/'main.fp8');np.zeros(73728,np.uint8).tofile(a.output/'skip.fp8')
y,x=np.mgrid[:n,:n];base=np.empty((n,n,4),np.float32);base[:]=[.25,.5,.75,1];base.tofile(a.output/'color.f32')
h=np.empty_like(base);h[:,:,0]=(x+.5)/n;h[:,:,1]=(y+.5)/n;h[:,:,2]=.125;h[:,:,3]=1;assert np.array_equal(h,h.astype(np.float16).astype(np.float32));h.tofile(a.output/'history.f32')
for name,dx in [('motion-zero',0.),('motion-one-pixel',1.)]:
 m=np.zeros_like(base);m[:,:,0]=dx;m.tofile(a.output/(name+'.f32'))
m=np.zeros_like(base);m[:,:,0]=.25;m[:,:,1]=.375;m.tofile(a.output/'motion-subpixel-diagonal.f32')
for src,dst in [('weights.bin','weights.bin'),('blend.bin','blend.bin')]:shutil.copyfile(a.source_root/'release/native-post70/smoke'/src,a.output/dst)
(a.output/'cases.json').write_text(json.dumps({'scope':'controlled original-CUBIN post-only, not game/API texture-format parity or video reproduction','width':n,'height':n,'texture_format':'self-created CUDA_ARRAY FLOAT4, linear clamp, normalized coordinates, half-exact texel values','packet_layout_source':'original NGX310.8 legal second Eval Reset0, valid1920x1080 observed; full-rect transforms adapted to16x16','cases':['closed-history','zero-motion','one-pixel-motion'],'main_skip':'zero native views; head logit expected zero, sigmoid0.5','input_scale':.03125,'rgb_mode':1,'history6float_offset':'0x74','motion6float_offset':'0x8c','motion_uv_scale_offsets':['0xa4','0xa8']},indent=2)+'\n')
