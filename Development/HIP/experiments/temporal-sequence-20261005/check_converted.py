"""Synthetic converted-plan fixture exercises receipt/index binding; no source capture."""
import json
import tempfile
from pathlib import Path
import numpy as np
from validate_real_sequence import digest
from seal_converted import seal

with tempfile.TemporaryDirectory(prefix='dlss5-converted-proof-') as directory:
    root=Path(directory)
    frames=[]
    for i in range(2):
        encoded=np.ones((3,2,4),dtype='<f4');encoded.tofile(root/f'{i}-encoded.f32')
        np.zeros((3,2,2),dtype='<f4').tofile(root/f'{i}-coordinates.f32')
        text=('valid_width=2\nvalid_height=2\nprocessing_height=3\n'
              'color_policy=existing_codec_direct_fit_raw_FFX_not_FSR\n'
              'motion_policy=existing_native_coordinates_UV_direct_for_replay_diagnostic_pixel_displacement_separate\n')
        (root/f'{i}-conversion.txt').write_text(text)
        config=root/f'{i}.txt'
        config.write_text(f'encoded_output=D:\\fixture\\{i}-encoded.f32\ncoordinates_output=D:\\fixture\\{i}-coordinates.f32\nreceipt_output=D:\\fixture\\{i}-conversion.txt\n')
        frames.append(dict(frame_id=i,config=config.name,config_sha256=digest(config),source_reset=i==0,source_seed=None,experiment_seed=i))
    plan=root/'receipt.json';plan.write_text(json.dumps(dict(schema='dlss5.controlled-replay-plan.v1',windows_output_root='D:\\fixture',frames=frames)))
    result=seal(plan,root,root/'prepared.tsv')
    assert len(result['frames'])==2 and result['frames'][0]['source_seed'] is None
    assert not result['source_identity_verified']
    try:seal(plan,root,root/'prepared.tsv')
    except ValueError:pass
    else:raise AssertionError('overwrite accepted')
    (root/'0.txt').write_text('changed')
    try:seal(plan,root,root/'bad.tsv')
    except ValueError:pass
    else:raise AssertionError('config mismatch accepted')
print('CPU_CONVERTED_PASS: byte/geometry/mirror/finite/config SHA/index binding; source seed stays null')
