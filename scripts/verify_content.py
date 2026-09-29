"""Verify the reviewed baseline bytes, without claiming religious authenticity."""
import hashlib
import argparse
import json
from pathlib import Path

# Missing entries must not silently remove a religious collection from review.
REQUIRED_COLLECTIONS = {
    'assets/quran_master.json', 'assets/quran_duas.json',
    'assets/prayers_data.json', 'assets/hadeath/ahadeth.txt',
}

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--require-approved', action='store_true',
                    help='Also require content-owner approval metadata for release.')
args = parser.parse_args()
try:
    manifest = json.loads((root / 'content_manifest.json').read_text(encoding='utf-8'))
    if not isinstance(manifest, dict) or manifest.get('schemaVersion') != 1:
        raise ValueError('Unsupported manifest schema')
    collections = manifest.get('collections')
    if not isinstance(collections, list) or not all(isinstance(item, dict) for item in collections):
        raise ValueError('Collections must be a list of objects')
    paths = [item.get('path') for item in collections]
    if (not all(isinstance(path, str) for path in paths)
            or len(paths) != len(REQUIRED_COLLECTIONS)
            or set(paths) != REQUIRED_COLLECTIONS):
        raise ValueError('Exactly the four required content collections must be listed')
except (OSError, ValueError, TypeError) as error:
    raise SystemExit(f'Content manifest invalid: {error}') from None
failed = []
for item in collections:
    path = root / item['path']
    try:
        valid = (path.resolve().is_relative_to(root.resolve()) and path.is_file()
                 and hashlib.sha256(path.read_bytes()).hexdigest() == item.get('sha256'))
    except OSError:
        valid = False
    if not valid:
        failed.append(item['path'])
if failed:
    raise SystemExit('Content integrity changed; obtain content-owner review: ' + ', '.join(failed))
if args.require_approved:
    required = ('source', 'edition', 'license', 'reviewer', 'approvalDate', 'evidenceUrl')
    pending = [item['path'] for item in manifest['collections']
               if any(not isinstance(item.get(field), str) or not item[field].strip()
                      or item[field].strip().lower() == 'pending_owner_review' for field in required)]
    if manifest.get('approvalStatus') != 'approved' or pending:
        raise SystemExit('Release requires content-owner approval: ' +
                         ', '.join(pending or ['manifest approvalStatus']))
print(f"Content integrity passed for {len(manifest['collections'])} assets. Source approval is separate.")
