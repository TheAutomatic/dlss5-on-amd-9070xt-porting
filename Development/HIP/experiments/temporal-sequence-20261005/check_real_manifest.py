"""Small synthetic parser corruption fixtures; not a game source."""
import hashlib
import json
import tempfile
from pathlib import Path
from validate_real_sequence import validate

with tempfile.TemporaryDirectory(prefix='dlss5-manifest-proof-') as directory:
    root = Path(directory)
    raw = root / 'fixture.bin'
    raw.write_bytes(bytes(16))
    resource = dict(role='color', path=raw.name, dxgi_format=10, width=2, height=1,
                    row_bytes=16, bytes=16, sha256=hashlib.sha256(raw.read_bytes()).hexdigest())
    frames = [dict(schema='dlss5.real-sequence.v1', frame_id=i, timestamp_ms=10*i,
                   reset=i == 0, jitter=[0., 0.], pre_exposure=1., motion_scale=[1., 1.],
                   render=[2, 1], upscale=[2, 1], seed=None, timing_valid=False, source_kind='game_capture',
                   contract_verified=False, resources=[resource]) for i in range(2)]
    manifest = root / 'manifest.jsonl'
    (root/'COMPLETE').write_text('frames=2\n')
    def write():
        manifest.write_text(''.join(json.dumps(f)+'\n' for f in frames))
    write()
    report = validate(manifest)
    assert report['metadata_valid'] and not report['replay_ready']
    assert len(report['blockers']) == 5
    def rejected():
        write()
        try:
            validate(manifest)
        except ValueError:
            return
        raise AssertionError('corrupt capture accepted')
    frames[1]['frame_id'] = 3
    rejected()
    frames[1]['frame_id'] = 1
    frames[1]['timestamp_ms'] = 0
    rejected()
    frames[1]['timestamp_ms'] = 10
    resource['row_bytes'] = 8
    rejected()
    resource['row_bytes'] = 16
    resource['sha256'] = '0'*64
    rejected()
    resource['sha256'] = hashlib.sha256(raw.read_bytes()).hexdigest()
    resource['path'] = '../outside.bin'
    rejected()
print('CPU_MANIFEST_PASS: integrity/order/gap/pitch/hash/path guards; unverified contracts block replay')
