"""Only lockedM VT score changes; denominator/layout/QB2/AV remain old. CPU SPV build."""
from pathlib import Path
import argparse,subprocess,json,hashlib,os
p=argparse.ArgumentParser();p.add_argument('out',type=Path);a=p.parse_args();a.out.mkdir(parents=True,exist_ok=True)
r=Path('/tmp/claude-1000/ct/mz');arch=r/'windows/shaders/rdna4';tool=r/'toolchain/glslang/bin/glslang';defs=json.loads((arch/'pipelines.json').read_text())['pipelines']['vitattn']['defines'];source=(arch/'vit_attn.comp').read_text()
start=source.index('f16vec2 nr_vit_exp2(vec2 x) {');end=source.index('\n}',start)+2
new='''f16vec2 nr_vit_exp2(vec2 x) {
    precise vec2 scaled = x * vec2(0.08953857421875);
    precise vec2 affine = scaled + vec2(1.708984375);
    vec2 y = clamp(affine,vec2(1.439453125),vec2(1.9775390625));
    uvec2 h = (floatBitsToUint(y) >> 13u) - uvec2(0x1c000u);
    uvec2 mapped = ((h << 4u) + uvec2(0x4000u)) & uvec2(0xffffu);
    return unpackFloat2x16(mapped.x | (mapped.y << 16u));
}'''
checks=[];env=dict(os.environ,NR_Q32_DIRECT='1')
for side,s in [('old',source),('new',source[:start]+new+source[end:])]:
 src=a.out/(side+'.comp');src.write_text(s);pre=a.out/(side+'.pre.comp');spv=a.out/(side+'.spv')
 cmd=[str(tool),'-E','-I'+str(arch/'include')]+['-D'+d for d in defs]+[str(src)];res=subprocess.run(cmd,capture_output=True,text=True,check=True);pre.write_text(res.stdout)
 subprocess.run(['python3',str(r/'windows/build/quad_quant_glsl.py'),str(pre),str(pre)],env=env,check=True,capture_output=True)
 cmd=[str(tool),'-V','--target-env','vulkan1.3','-I'+str(arch/'include'),'-o',str(spv),str(pre)];res=subprocess.run(cmd,capture_output=True,text=True,check=True);(a.out/(side+'.log')).write_text(res.stdout+res.stderr)
 h=hashlib.sha256(spv.read_bytes()).hexdigest();checks.append({'side':side,'source_sha':hashlib.sha256(src.read_bytes()).hexdigest(),'SPV_sha':h,'compile_command':cmd})
locked=r.parent/'up/mz/spv/g_vitattn.spv';oldsha=hashlib.sha256(locked.read_bytes()).hexdigest();assert checks[0]['SPV_sha']==oldsha,'old SPV byte reappearance failed; do not run'
(a.out/'recipe.json').write_text(json.dumps({'locked_commit':'d1185d25141b1714d7837151b6fa782e6427568b','defines':defs,'NR_Q32_DIRECT':'1','old_locked_SPV_sha':oldsha,'old_reproduced':True,'checks':checks,'scope':'only nr_vit_exp2 HALFscore→preciseF32mul/add/truncmap; effective HALF64den unchanged, noF32K16denclaim;QB2/layout/driver/AV/exit unchanged','GPU_not_run':True},indent=2)+'\n')
