"""Verify the reviewed baseline bytes, without claiming religious authenticity."""
import hashlib
import argparse
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--require-approved', action='store_true',
                    help='Also require content-owner approval metadata for release.')
args = parser.parse_args()
manifest = json.loads((root / 'content_manifest.json').read_text(encoding='utf-8'))
failed = []
for item in manifest['collections']:
    path = root / item['path']
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != item['sha256']:
        failed.append(item['path'])
if failed:
    raise SystemExit('Content integrity changed; obtain content-owner review: ' + ', '.join(failed))
if args.require_approved:
    required = ('source', 'edition', 'license', 'reviewer', 'approvalDate', 'evidenceUrl')
    pending = [item['path'] for item in manifest['collections']
               if any(not isinstance(item.get(field), str) or not item[field].strip()
                      or item[field] == 'pending_owner_review' for field in required)]
    if manifest.get('approvalStatus') != 'approved' or pending:
        raise SystemExit('Release requires content-owner approval: ' +
                         ', '.join(pending or ['manifest approvalStatus']))
print(f"Content integrity passed for {len(manifest['collections'])} assets. Source approval is separate.")
