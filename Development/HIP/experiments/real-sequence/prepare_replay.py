#!/usr/bin/env python3
"""Prepare explicit controlled conversion configs and SHA receipts; never runs a GPU."""
import argparse, hashlib, json, math, pathlib, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent/'temporal-sequence-20261005'))
from validate_real_sequence import validate

def digest(p):
    h=hashlib.sha256()
    with p.open('rb') as f:
        for b in iter(lambda:f.read(1048576),b''):h.update(b)
    return h.hexdigest()

def require(ok,msg):
    if not ok:raise ValueError(msg)

def prepare(manifest,recipe_file,out,exe,shader_assets,win_source,win_output,win_assets):
    report=validate(manifest)
    require((manifest.parent/'COMPLETE').is_file(),'capture COMPLETE marker missing')
    recipe=json.loads(recipe_file.read_text())
    require(recipe.get('controlled_replay_only') is True,'controlled_replay_only=true required')
    require(recipe.get('pre_exposure_policy')=='captured','explicit captured pre_exposure policy required')
    require(recipe.get('motion_scale_policy')=='captured','explicit captured motion_scale policy required')
    require(recipe.get('jitter_policy')=='preserve_metadata_not_applied','converter does not apply jitter; acknowledge policy')
    require(recipe.get('depth_policy')=='preserved_not_applied','converter does not apply depth; acknowledge policy')
    require(recipe.get('network_seed_policy') in ('fixed0','frame_index'),'explicit network seed experiment policy required')
    settings=recipe.get('settings',{})
    required=('DLSS5_NETWORK_HEIGHT','DLSS5_NETWORK_FREE_RES','DLSS5_NETWORK_1080_ROWS','DLSS5_CODEC_SRGB','DLSS5_FIT_LARGE','exposure_scale','transfer_strength','color_strength','paper_white','motion_sign','use_exposure')
    require(set(settings)==set(required),'settings must explicitly contain exactly '+','.join(required))
    require(type(settings['motion_sign']) in (int,float) and settings['motion_sign'] in (-1,1),'motion_sign must be explicit +/-1 experiment factor')
    require(type(settings['use_exposure']) is int and settings['use_exposure'] in (0,1),'use_exposure must be explicit 0/1')
    for k in ('exposure_scale','transfer_strength','color_strength','paper_white'):
        require(type(settings[k]) in (int,float) and math.isfinite(settings[k]),'finite '+k+' required')
    require(0<settings['paper_white']<=64 and settings['exposure_scale']>0,'positive paper_white<=64 and exposure_scale required')
    require(all(0<=settings[k]<=3 for k in ('transfer_strength','color_strength')),'codec strengths outside actual shader contract')
    require(all(p.is_absolute() for p in (win_source,win_output,win_assets)),'Windows path mappings must be absolute')
    require(exe.is_file(),'compiled converter executable required')
    shaders={str(p.relative_to(shader_assets)):digest(p) for p in sorted(shader_assets.rglob('*.hlsl'))}
    for name in ('native_codec_encode.hlsl','native_game_rgb_input.hlsl','native_temporal_feed.hlsl','native_temporal_coordinates.hlsl'):
        require(name in shaders,'shader assets missing '+name)
    require(not out.exists(),'refuse to overwrite conversion plan directory')
    frames=[json.loads(x) for x in manifest.read_text().splitlines() if x.strip()]
    configs=[]
    for index,f in enumerate(frames):
        resources={r['role']:r for r in f['resources'] if not r.get('missing')}
        require('color' in resources and 'motion' in resources,'color and motion required')
        if settings['use_exposure']:require('exposure' in resources,'explicit exposure enabled but raw is missing')
        require([resources['color']['width'],resources['color']['height']]==f['render'],'subrect conversion not implemented')
        config={**settings,'assets':str(win_assets),'render_width':f['render'][0],'render_height':f['render'][1],
                'pre_exposure':f['pre_exposure'],'motion_scale_x':f['motion_scale'][0],'motion_scale_y':f['motion_scale'][1]}
        for role in ('color','motion','exposure'):
            if role not in resources:continue
            r=resources[role];rel=pathlib.PurePosixPath(r['path'])
            require(not rel.is_absolute() and '..' not in rel.parts,'raw path must stay within mapped capture directory')
            for k,v in [('path',str(win_source.joinpath(*rel.parts))),('width',r['width']),('height',r['height']),('row_bytes',r['row_bytes']),('format',r['dxgi_format'])]:config[role+'_'+k]=v
        stem=str(f['frame_id'])
        config.update(coordinates_output=str(win_output/(stem+'-coordinates.uv32f')),encoded_output=str(win_output/(stem+'-encoded.rgba32f')),motion_output=str(win_output/(stem+'-motion.xy32f')),receipt_output=str(win_output/(stem+'-conversion.txt')))
        text=''.join(str(k)+'='+str(v)+'\n' for k,v in config.items())
        require(all('\n' not in str(v) and '\r' not in str(v) for v in config.values()),'config values cannot contain newlines')
        configs.append((stem+'.config.txt',text,f,index))
    out.mkdir(parents=True)
    receipt={'schema':'dlss5.controlled-replay-plan.v1','manifest_sha256':digest(manifest),'recipe_sha256':digest(recipe_file),
             'converter_sha256':digest(exe),'shader_sha256':shaders,'source_identity_verified':False,
             'source_contract_verified':False,'source_effective_flags_verified':False,'source_config_lines_sha256':digest(manifest.parent/'config-lines.txt') if (manifest.parent/'config-lines.txt').is_file() else None,'game_pre_fsr_parity_verified':False,'timing_valid':False,'replay_motion_policy':'direct_native_coordinates_uv32f','motion_xy_policy':'diagnostic_only_no_reconstruction_roundtrip',
             'validation':report,'recipe':recipe,'windows_source_root':str(win_source),'windows_output_root':str(win_output),'windows_assets_root':str(win_assets),'frames':[]}
    for name,text,f,index in configs:
        p=out/name;p.write_text(text,encoding='utf-8')
        receipt['frames'].append({'frame_id':f['frame_id'],'config':name,'config_sha256':digest(p),'source_seed':f['seed'],
           'experiment_seed':0 if recipe['network_seed_policy']=='fixed0' else index,'source_reset':f['reset'],
           'source_jitter':f['jitter'],'source_flags':f['ffx_flags'],'source_resources':f['resources']})
    (out/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
    return {'prepared_frames':len(configs),'receipt':str(out/'receipt.json'),'controlled_only':True,'gpu_executed':False}

if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__)
    for name in ('manifest','recipe','output','converter','shader_assets'):p.add_argument(name,type=pathlib.Path)
    for name in ('windows-source','windows-output','windows-assets'):p.add_argument('--'+name,required=True,type=pathlib.PureWindowsPath)
    a=p.parse_args()
    try:print(json.dumps(prepare(a.manifest.resolve(),a.recipe.resolve(),a.output,a.converter,a.shader_assets,a.windows_source,a.windows_output,a.windows_assets),indent=2))
    except (ValueError,OSError,KeyError,TypeError) as e:p.exit(1,'REPLAY_PREPARE_FAIL: '+str(e)+'\n')
