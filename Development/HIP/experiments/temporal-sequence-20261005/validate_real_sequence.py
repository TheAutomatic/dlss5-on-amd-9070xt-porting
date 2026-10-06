"""CPU validation of dlss5.real-sequence.v1; does not decode/guess motion or history."""
import argparse
import hashlib
import json
import math
from pathlib import Path

# Known raw storage sizes only; these do not establish the shader semantic contract.
PIXEL_BYTES = {2: 16, 10: 8, 16: 8, 34: 4, 41: 4, 28: 4, 29: 4, 87: 4, 91: 4,
               'R32G32B32A32_FLOAT': 16, 'R16G16B16A16_FLOAT': 8,
               'R32G32_FLOAT': 8, 'R16G16_FLOAT': 4, 'R32_FLOAT': 4,
               'DXGI_FORMAT_R16G16B16A16_FLOAT': 8,
               'DXGI_FORMAT_R16G16_FLOAT': 4, 'DXGI_FORMAT_R32_FLOAT': 4}

def require(condition, message):
    if not condition:
        raise ValueError(message)

def vector(value, size, label, positive=False):
    require(isinstance(value, list) and len(value) == size, label + ' shape')
    require(all(isinstance(x, (int, float)) and not isinstance(x, bool) and math.isfinite(x)
                and (not positive or x > 0) for x in value), label + ' values')

def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(chunk)
    return h.hexdigest()

def validate(manifest):
    root = manifest.resolve().parent
    frames = [json.loads(line) for line in manifest.read_text().splitlines() if line.strip()]
    require(len(frames) >= 2, 'at least two consecutive frames required')
    require(not (root/'FAILED.txt').exists(), 'capture marked failed')
    marker = root/'COMPLETE'
    require(marker.is_file(), 'capture completion marker missing')
    require(marker.read_text().strip() == 'frames='+str(len(frames)), 'completion frame count mismatch')
    blockers = set()
    previous = None
    for f in frames:
        require(f.get('schema') == 'dlss5.real-sequence.v1', 'schema mismatch')
        require(f.get('source_kind') == 'game_capture', 'source must be explicitly labelled game_capture')
        frame = f.get('frame_id')
        require(type(frame) is int and frame >= 0, 'frame_id')
        timestamp = f.get('timestamp_ms')
        require(isinstance(timestamp, (int, float)) and math.isfinite(timestamp), 'timestamp_ms')
        require(type(f.get('reset')) is bool, 'reset must be recorded')
        if previous:
            require(frame > previous['frame_id'] and timestamp > previous['timestamp_ms'], 'frame order')
            if frame != previous['frame_id'] + 1:
                require(f['reset'], 'frame gap without explicit reset')
                blockers.add('capture contains a frame gap; no interpolation performed')
        vector(f.get('jitter'), 2, 'jitter')
        vector(f.get('motion_scale'), 2, 'motion_scale')
        vector(f.get('render'), 2, 'render', True)
        require(all(type(x) is int for x in f['render']), 'render integer extent')
        vector(f.get('upscale'), 2, 'upscale')
        require(all(type(x) is int and x >= 0 for x in f['upscale']), 'upscale integer extent')
        if f['upscale'] == [0, 0]:
            blockers.add('FFX upscale deferred to context; output extent must be recorded separately')
        else:
            require(all(x > 0 for x in f['upscale']), 'partial zero upscale extent')
        if f.get('source_identity_verified') is not True:
            blockers.add('transient resource/source identity not verified by capture integrity')
        exposure = f.get('pre_exposure')
        require(isinstance(exposure, (int, float)) and math.isfinite(exposure) and exposure > 0,
                'pre_exposure')
        if previous and f['render'] != previous['render']:
            blockers.add('render extent transition requires explicit network/history resize mapping')
        if f.get('seed') is None:
            blockers.add('network seed not recorded; no counter invented')
        else:
            require(type(f['seed']) is int and 0 <= f['seed'] <= 0xffffffff, 'seed')
        if f.get('contract_verified') is not True:
            blockers.add('color/MV/depth/exposure conversion contract not verified')
        require(f.get('timing_valid') is False, 'capture timing must be labelled invalid')
        resources = f.get('resources')
        require(isinstance(resources, list), 'resources array')
        seen = set()
        for resource in resources:
            role = resource.get('role')
            require(isinstance(role, str) and role not in seen, 'duplicate/missing role')
            seen.add(role)
            if resource.get('missing') is True:
                if role in ('color', 'motion', 'depth'):
                    blockers.add(role + ' missing in one or more frames')
                continue
            width, height, stride = (resource.get(k) for k in ('width', 'height', 'row_bytes'))
            require(all(type(x) is int and x > 0 for x in (width, height, stride)), role + ' extent/pitch')
            bpp = PIXEL_BYTES.get(resource.get('dxgi_format'))
            if bpp is None:
                blockers.add(role + ' raw format unsupported by replay preparation')
            else:
                require(stride >= width * bpp, role + ' pitch smaller than row')
            path = (root / resource.get('path', '')).resolve()
            require(path.is_relative_to(root) and path.is_file(), role + ' local file')
            rows = resource.get('rows', height)
            require(type(rows) is int and rows > 0, role + ' copied rows')
            if rows != height:
                blockers.add(role + ' block/plane row layout needs decoding before replay')
            require(path.stat().st_size == resource.get('bytes') == stride * rows,
                    role + ' byte count/pitch mismatch')
            require(digest(path) == resource.get('sha256'), role + ' SHA mismatch/missing')
        for role in ('color', 'motion', 'depth'):
            if role not in seen:
                blockers.add(role + ' role not recorded')
        previous = f
    return {'metadata_valid': True, 'frames': len(frames), 'first_frame': frames[0]['frame_id'],
            'last_frame': frames[-1]['frame_id'], 'replay_ready': not blockers,
            'blockers': sorted(blockers), 'timing_valid': False,
            'scope': 'file integrity and metadata only; no native temporal parity or quality claim'}

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('manifest', type=Path)
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    try:
        report = validate(args.manifest)
        output = json.dumps(report, indent=2) + '\n'
        if args.report:
            args.report.write_text(output)
        print(output, end='')
    except (ValueError, OSError, TypeError, KeyError) as error:
        parser.exit(1, 'SEQUENCE_METADATA_FAIL: ' + str(error) + '\n')
