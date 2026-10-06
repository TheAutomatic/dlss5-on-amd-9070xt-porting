"""Seal raw capture hashes beside the unmodified original JSONL; no semantic guesses."""
import argparse
import json
import os
import tempfile
from pathlib import Path
from validate_real_sequence import digest, require, validate

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('manifest', type=Path)
    args = parser.parse_args()
    try:
        source = args.manifest.resolve()
        destination = source.with_name(source.stem + '-sealed.jsonl')
        require(not destination.exists(), 'sealed destination already exists')
        frames = [json.loads(line) for line in source.read_text().splitlines() if line.strip()]
        for frame in frames:
            for resource in frame['resources']:
                if resource.get('missing') is True:
                    continue
                path = (source.parent / resource['path']).resolve()
                require(path.is_relative_to(source.parent) and path.is_file(), 'local raw file required')
                actual = digest(path)
                require('sha256' not in resource or resource['sha256'] == actual, 'existing SHA mismatch')
                resource['sha256'] = actual
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=source.parent,
                                         prefix='.seal-', suffix='.jsonl', delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(''.join(json.dumps(frame, separators=(',', ':'))+'\n' for frame in frames))
        try:
            report = validate(temporary)
            # Exclusive publication: a concurrent sealer never overwrites another result.
            os.link(temporary, destination)
        finally:
            temporary.unlink(missing_ok=True)
        print(json.dumps({'sealed': str(destination), **report}, indent=2))
    except (ValueError, OSError, TypeError, KeyError) as error:
        parser.exit(1, 'SEQUENCE_SEAL_FAIL: ' + str(error) + '\n')
