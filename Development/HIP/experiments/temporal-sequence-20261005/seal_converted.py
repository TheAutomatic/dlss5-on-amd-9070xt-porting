"""Validate converted bytes and bind a controlled prepared-index to the capture plan."""
import argparse
import hashlib
import json
from pathlib import Path, PureWindowsPath
import numpy as np
from validate_real_sequence import digest, require

def seal(plan_path, converted, index):
    plan = json.loads(plan_path.read_text())
    require(plan['schema'] == 'dlss5.controlled-replay-plan.v1', 'plan schema')
    require(not index.exists(), 'refuse to overwrite prepared index')
    root = converted.resolve()
    records = []
    index_lines = ['# controlled codec fit; source seed/identity unverified; fixed0/counter replay factors\n']
    win_root = PureWindowsPath(plan['windows_output_root'])
    for frame in plan['frames']:
        config_file = plan_path.parent / frame['config']
        require(digest(config_file) == frame['config_sha256'], 'conversion config SHA')
        config = dict(line.split('=', 1) for line in config_file.read_text().splitlines() if line)
        names = {k: PureWindowsPath(config[k]).name for k in
                 ('encoded_output', 'coordinates_output', 'receipt_output')}
        receipt = dict(line.split('=', 1) for line in (root/names['receipt_output']).read_text().splitlines() if line)
        w, h, ph = (int(receipt[k]) for k in ('valid_width', 'valid_height', 'processing_height'))
        require(w >= 2 and h >= 2 and h <= ph <= 2*h-1, 'conversion geometry')
        require(receipt['color_policy'] == 'existing_codec_direct_fit_raw_FFX_not_FSR', 'codec policy changed')
        require(receipt['motion_policy'] == 'existing_native_coordinates_UV_direct_for_replay_diagnostic_pixel_displacement_separate', 'direct UV receipt required')
        inputs = {}
        for key, channels in (('encoded_output', 4), ('coordinates_output', 2)):
            path = root / names[key]
            require(path.stat().st_size == w*ph*channels*4, key + ' byte extent')
            data = np.memmap(path, dtype='<f4', mode='r', shape=(ph,w,channels))
            require(np.isfinite(data).all(), key + ' finite')
            if channels == 4:
                require(np.all(data[:,:,3] == 1), 'encoded alpha1')
                require(np.array_equal(data[h:], data[2*h-np.arange(h,ph)-2]), 'encoded bottom mirror')
            inputs[key] = dict(path=names[key], sha256=digest(path), bytes=path.stat().st_size)
        frame_id = frame['frame_id']
        fields = [frame_id, w, h, ph, int(frame['source_reset']), 1,
                  str(win_root/names['encoded_output']), str(win_root/names['coordinates_output'])]
        require(all('\t' not in str(x) and '\n' not in str(x) for x in fields), 'index field delimiter')
        index_lines.append('\t'.join(map(str, fields))+'\n')
        records.append(dict(frame_id=frame_id, inputs=inputs, conversion_receipt_sha256=digest(root/names['receipt_output']),
                            source_seed=frame['source_seed'], experiment_seed=frame['experiment_seed']))
    require(len(records) >= 2, 'prepared sequence needs2+ frames')
    index.write_text(''.join(index_lines))
    receipt = dict(plan_sha256=digest(plan_path), index_sha256=digest(index), frames=records,
                   scope='controlled replay input integrity; direct raw FFX fit, no FSR, no native timing/quality claim',
                   source_identity_verified=False, source_contract_verified=False, timing_valid=False)
    index.with_suffix('.receipt.json').write_text(json.dumps(receipt, indent=2)+'\n')
    return receipt

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('plan', type=Path)
    parser.add_argument('converted_directory', type=Path)
    parser.add_argument('output_index', type=Path)
    args = parser.parse_args()
    try:
        receipt = seal(args.plan, args.converted_directory, args.output_index)
        print(json.dumps({'controlled_prepared_frames': len(receipt['frames']), 'index': str(args.output_index)}, indent=2))
    except (ValueError,OSError,KeyError,TypeError) as error:
        parser.exit(1, 'CONVERTED_SEAL_FAIL: '+str(error)+'\n')
