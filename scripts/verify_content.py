"""Verify the reviewed baseline bytes, without claiming religious authenticity."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
manifest = json.loads((root / 'content_manifest.json').read_text(encoding='utf-8'))
failed = []
for item in manifest['collections']:
    path = root / item['path']
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != item['sha256']:
        failed.append(item['path'])
if failed:
    raise SystemExit('Content integrity changed; obtain content-owner review: ' + ', '.join(failed))
print(f"Content integrity passed for {len(manifest['collections'])} assets. Source approval is separate.")
