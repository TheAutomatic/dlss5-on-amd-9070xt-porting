#!/usr/bin/env python3
import pathlib,sys,hashlib,json
here=pathlib.Path(__file__).resolve().parent
root=here.parents[3]
out=pathlib.Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
pre=(root/'src/native_pre_upscale.h').read_text()
needle='  auto*color=static_cast<ID3D12Resource*>(d.resources[0].resource);'
assert pre.count(needle)==1
pre=pre.replace(needle,'  if(Mode()==2)NativeSequenceCapture::Record(q,d,replay_states,j.frame,j.record_device);\n'+needle)
probe=(root/'src/native_submission_order_probe.cpp').read_text()
needle='#include "native_pre_upscale.h"'
assert probe.count(needle)==1
probe=probe.replace(needle,'#include "capture.h"\n'+needle)
(out/'native_pre_upscale.h').write_text(pre)
(out/'native_submission_order_probe.cpp').write_text(probe)
(out/'capture.h').write_bytes((here/'capture.h').read_bytes())
(out/'source.json').write_text(json.dumps({p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [out/'native_pre_upscale.h',out/'native_submission_order_probe.cpp',out/'capture.h']},indent=2)+'\n')
