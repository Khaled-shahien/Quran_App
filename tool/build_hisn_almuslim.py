"""Builds assets/hisn_almuslim.json from the hisnmuslim.com Arabic API.

Usage: python -I -X utf8 tool/build_hisn_almuslim.py <download_dir> <out.json>

<download_dir> holds husn_ar.json (the chapter index from
https://www.hisnmuslim.com/api/ar/husn_ar.json) and chapters/<ID>.json
(https://www.hisnmuslim.com/api/ar/<ID>.json).

The Arabic text of every entry is copied exactly as served: it is never
retyped, trimmed or corrected here (owner rule: religious text is only
ever copied programmatically). Chapter order is the API's. Audio links
are not kept. The API carries no hadith references; see
content_manifest.json for the review that is still needed.
"""
import json
import sys

src, out_path = sys.argv[1:3]
index = json.load(open(f'{src}/husn_ar.json', encoding='utf-8-sig'))
chapters_index = next(iter(index.values()))

chapters = []
total = 0
for entry in chapters_index:
    cid = int(entry['ID'])
    data = json.load(open(f'{src}/chapters/{cid}.json', encoding='utf-8-sig'))
    if len(data) != 1:
        raise SystemExit(f'chapter {cid}: expected one title')
    (title, items), = data.items()
    if title != entry['TITLE']:
        raise SystemExit(f'chapter {cid}: title differs from the index')
    kept = []
    for item in items:
        text = item['ARABIC_TEXT']
        if not isinstance(text, str) or not text.strip():
            raise SystemExit(f'chapter {cid}: empty entry {item.get("ID")}')
        repeat = int(str(item.get('REPEAT') or '1').strip() or '1')
        kept.append({'id': int(item['ID']), 'text': text, 'repeat': max(1, repeat)})
    total += len(kept)
    chapters.append({'id': cid, 'title': title, 'items': kept})

out = {
    'schemaVersion': 1,
    'source': 'Hisn al-Muslim (Sa‘id ibn Ali ibn Wahf al-Qahtani), Arabic '
              'text from the hisnmuslim.com API, downloaded 2026-11-18',
    'chapters': chapters,
}
with open(out_path, 'w', encoding='utf-8', newline='\n') as fh:
    json.dump(out, fh, ensure_ascii=False, indent=1)
    fh.write('\n')
print(f'{len(chapters)} chapters, {total} entries')
