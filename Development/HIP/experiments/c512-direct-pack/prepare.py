from pathlib import Path
import argparse,subprocess,json,hashlib,re
p=argparse.ArgumentParser();p.add_argument('--output',type=Path,required=True);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
r=Path(__file__).resolve().parents[4];get=lambda n:subprocess.check_output(['git','show','058ec7c1:hip/'+n],cwd=r,text=True)
d=''.join('#define '+v+'\n' for v in ['HIP_ISA_HALF 1','HIP_PREPACKED_WEIGHTS 1','HIP_BRANCHLESS_F 1','C512_MIX_OCC_LDS 4096','C512_F_MASK 1','HIP_BYTE_F_ADD0 1','C512_FFN_ONE 2','C512_FFN_F8W 1'])
deep=get('deep_fast.hip');proof=Path(__file__).with_name('proof_kernels.inc').read_text()
for mode in ['base','0','1','2','3']:
 inc=get('c512_m32_deep.inc') if mode=='base' else (r/'hip/c512_m32_deep.inc').read_text()
 text=d+('' if mode=='base' else '#define C512_DIRECT_PACK '+mode+'\n')+deep+'\n'+inc+'\n'+proof
 (a.output/f'{mode}.generated.hip').write_text(text)
def body(s,signature):
 i=s.index(signature);i=s.index('{',i);level=1;j=i+1
 while level:level+=(s[j]=='{')-(s[j]=='}');j+=1
 return re.sub(r'\s+','',s[i:j])
old=(r/'Development/HIP/experiments/f-sweep/probe_a.hip').read_text()
for name,oldname in [('F','F'),('fp8_add0','add0')]:
 lhs,rhs=body(deep,'DEV float '+name+'('),body(old,'DEV float '+oldname+'(');assert lhs==rhs,(name,lhs,rhs)
proofmeta={'F_body_same_as_all_2pow32_f_sweep':True,'fp8_add0_body_same_as_all_2pow32_f_sweep':True,'previous_probe_source_sha256':hashlib.sha256(old.encode()).hexdigest(),'current_deep_source_sha256':hashlib.sha256(deep.encode()).hexdigest(),'preserved_compound_c512_hq':body(deep,'DEV float c512_hq('),'generated_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in a.output.glob('*.hip')}}
(a.output/'source-proof.json').write_text(json.dumps(proofmeta,indent=2)+'\n')
