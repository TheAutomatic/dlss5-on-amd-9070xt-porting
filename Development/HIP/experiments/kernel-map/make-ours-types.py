from pathlib import Path
import json
root=Path('/home/lmxxf/work/ai-theorys-study/wechat/assets/297');names=sorted(set(l.split(',')[2] for l in (root/'Development/results/deep-layers-20260929/topology-1080.csv').read_text().splitlines()));r={}
def add(n,i,o,note='',weights=[]):r[n]={'input_types':{str(k):v for k,v in i.items()},'output_types':{str(k):v for k,v in o.items()},'weight_args':weights,'special':note}
for n in names:
 if '_wave2_' in n:
  up=n.endswith('_up');bi='_bi' in n;bo='_bo' in n or up
  add(n,{0:'f32' if up or not bi else 'fp8',**({12:'f32'} if up else {})},{3:'fp8' if bo else 'f32'},'in声明float*但bi为FP8 raster；up低分辨率输入及skip都f32。', [1,2]+([11] if up else []))
 elif n in ['c32_wave1_chain','c32_wave1_mapped']:
  add(n,{0:'fp8' if n.endswith('chain') else 'f32'},{3:'fp8'},'chain为window-major FP8；mapped反解uchar*为raster f32，raw标志不改此导出实际类型。',[1,2])
 elif n.startswith('c32_wave1_finish'):
  add(n,{0:'fp8'},{3:'f32',4:'f32'},'main为raster F值仍存f32，down池化F值也f32；half仅内部residual，非输出dtype。',[1,2])
 elif n=='c32_wave1_prefix':add(n,{0:'f32',1:'f32'},{4:'fp8',5:'f32'},'rgba0强转float*，每像素4float；history也是RGBA f32，temporal=0不读。main虽然float*实际prefix写byte，down为f32。',[2,3])
 elif n=='c32_wave1_post':add(n,{0:'f32',1:'fp8',2:'f32',5:'f32'},{7:'f32'},'low为半分辨率32通道f32；skip高分辨率FP8；color是RGBA f32，rgb输出3float/pixel。',[3,4,6])
 elif n=='c32_wave1_up':add(n,{0:'f32',2:'f32'},{5:'fp8'},'low虽然uchar*实际f32，skip也是f32；output为window-major FP8。',[1,3,4])
 elif n=='c512_qkv_attention_compact':add(n,{0:'fp8'},{2:'fp8'},'input紧凑16token×512 tiled FP8；output attention padded窗口/raster FP8，按work形状检查。',[1])
 elif n.startswith('decoder_project2x_h16w'):add(n,{0:'f32',2:'f32'},{3:'fp8' if n.endswith('byteout') else 'f32'},'h16w仅权重half，不是输入/skip half；byteout强转输出byte。',[1])
 elif n=='mh_attention_project_frag_c512':add(n,{0:'fp8',1:'f32'},{3:'f32'},'av8 FP8，feature残差f32；output裁剪后的raster f32。',[2])
 elif n=='mh_pool':add(n,{0:'f32'},{1:'f32'},'raw和pooled均f32；内部H/F量化不改变存储。')
 elif n.startswith('mh_pool_project_'):add(n,{0:'f32'},{2:'f32'},'group版本融合pool，raw输入仍f32；production_h16w输入已pool f32。h16w/frag只指权重。',[1])
 elif n=='split_mix_blocked_h16w_m32':add(n,{0:'f32'},{2:'f32'},'MixHalf是权重布局；输入不是FP8。',[1])
 elif n=='split_ffn_fused_fp8_t8':add(n,{0:'f32'},{2:'f32',3:'fp8'},'同一contract值双输出；t8仅arg3 byte，arg2保留float。',[1])
 elif n=='split_projection_frag':add(n,{0:'fp8',2:'f32'},{3:'f32',4:'fp8'},'contract8输入与skip f32，双输出。',[1])
 elif n=='vit_gather':add(n,{0:'f32'},{2:'f32'},'arg1为固定indices fixture，勿随机浮点初始化。',[1])
 elif n=='vit_pack_input':add(n,{0:'f32',3:'zero'},{1:'fp8'},'arg1 uint*实际4个FP8 packed word；gate3必须zero以执行。')
 elif n=='vit_attention_fused_640_bytein_bout':add(n,{0:'fp8',3:'zero'},{1:'fp8'},'声明float*但ByteInput/ByteOutput都为true；gate3零。')
 elif n=='vit_expand_blocked_fp8_frag_bytein':add(n,{0:'fp8',6:'zero'},{2:'fp8'},'输入/hidden输出都byte；gate6零。',[1])
 elif n=='vit_stream_contract_frag_hout':add(n,{0:'fp8',2:'f32',7:'zero'},{3:'half'},'hidden FP8，原输入残差f32，half-out为IEEE half位模式；gate7零。',[1])
 elif n=='vit_stream_qkv_frag_hin':add(n,{0:'half',4:'zero'},{2:'fp8'},'hin真实half input；QKV byte out；gate4零。',[1])
 elif n=='vit_stream_project_n64_bh':add(n,{0:'fp8',2:'half',7:'zero'},{3:'f32'},'b=AV byte，h=skip half；最终输出仍f32。gate7零。',[1])
 else:raise RuntimeError(n)
assert set(r)==set(names)
Path('/tmp/kernel-map/ours-types.json').write_text(json.dumps(r,ensure_ascii=False,indent=2));print(len(r),'kernels covered')
