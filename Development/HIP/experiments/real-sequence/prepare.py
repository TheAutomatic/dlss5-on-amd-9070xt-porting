#!/usr/bin/env python3
import pathlib,sys,hashlib,json
here=pathlib.Path(__file__).resolve().parent
root=here.parents[3]
out=pathlib.Path(sys.argv[1]);out.mkdir(parents=True,exist_ok=True)
pre=(root/'src/native_pre_upscale.h').read_text()
needle='  auto*color=static_cast<ID3D12Resource*>(d.resources[0].resource);'
assert pre.count(needle)==1
pre=pre.replace(needle,'  if(Mode()==2)NativeSequenceCapture::Record(q,d,replay_states,j.frame,j.record_device,j.following_work==0&&!j.capture_unsafe);\n'+needle)
pre=pre.replace('bool uncertain{};unsigned following_work{};', 'bool uncertain{},capture_unsafe{};unsigned following_work{};')
pre=pre.replace('if(v.Type!=D3D12_RESOURCE_BARRIER_TYPE_TRANSITION)continue;', 'if(v.Type==D3D12_RESOURCE_BARRIER_TYPE_ALIASING){j.capture_unsafe=true;continue;}if(v.Type!=D3D12_RESOURCE_BARRIER_TYPE_TRANSITION)continue;')
probe=(root/'src/native_submission_order_probe.cpp').read_text()
needle='#include "native_pre_upscale.h"'
assert probe.count(needle)==1
probe=probe.replace(needle,'#include "capture.h"\n'+needle)
probe=probe.replace('static void STDMETHODCALLTYPE execute_native(ID3D12CommandQueue*q,UINT count,ID3D12CommandList*const*lists){', 'static void STDMETHODCALLTYPE execute_native(ID3D12CommandQueue*q,UINT count,ID3D12CommandList*const*lists){\n NativeSequenceCapture::ObserveSubmissionThread();')
events=['copy_resource','copy_buffer_region','copy_buffer_to_texture','copy_texture_region','copy_texture_to_buffer','resolve_texture_region','clear_depth_stencil_view','clear_render_target_view','clear_unordered_access_view_uint','clear_unordered_access_view_float','dispatch_mesh','dispatch_rays','draw_or_dispatch_indirect']
registrations='\n'.join('  reshade::register_event<reshade::addon_event::'+event+'>([](reshade::api::command_list*c,auto...){pre_upscale_work(c);return false;});' for event in events)
probe=probe.replace('  reshade::register_event<reshade::addon_event::present>(on_present);',registrations+'\n  reshade::register_event<reshade::addon_event::present>(on_present);')
(out/'native_pre_upscale.h').write_text(pre)
(out/'native_submission_order_probe.cpp').write_text(probe)
(out/'capture.h').write_bytes((here/'capture.h').read_bytes())
(out/'source.json').write_text(json.dumps({p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in [out/'native_pre_upscale.h',out/'native_submission_order_probe.cpp',out/'capture.h']},indent=2)+'\n')
