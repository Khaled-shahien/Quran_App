"""Builds assets/hadeath/hadeethenc_nawawi.json from HadeethEnc API answers.

Usage:
  python -I -X utf8 tool/build_hadith_hadeethenc.py <api_dir> <out.json>

<api_dir> holds one file per hadith, `<id>.json`, saved from
https://hadeethenc.com/api/v1/hadeeths/one/?language=ar&id=<id>.
tool/hadith_hadeethenc_ids.json maps the app's hadith numbers (1-50, the
Forty of al-Nawawi completed by Ibn Rajab) to HadeethEnc ids; it was made
by matching each hadith's text and checked hadith by hadith.

Every text field is copied exactly as the API returns it; nothing is
edited. The build fails if a mapped hadith is missing or a field is empty.
"""
import json
import sys
from pathlib import Path

FIELDS = ('title', 'hadeeth', 'attribution', 'grade', 'explanation',
          'reference')


def main(api_dir: str, out: str) -> None:
    ids = json.loads(
        (Path(__file__).parent / 'hadith_hadeethenc_ids.json').read_text(
            encoding='utf-8'))
    items = []
    for number in range(1, 51):
        hid = ids[str(number)]
        data = json.loads(
            (Path(api_dir) / f'{hid}.json').read_text(encoding='utf-8'))
        if str(data.get('id')) != str(hid):
            raise SystemExit(f'{number}: answer is for {data.get("id")}, not {hid}')
        item = {'number': number, 'id': str(hid)}
        for field in FIELDS:
            value = data.get(field)
            if not isinstance(value, str) or not value.strip():
                raise SystemExit(f'{number} ({hid}): empty {field}')
            item[field] = value
        hints = data.get('hints') or []
        if not all(isinstance(h, str) for h in hints):
            raise SystemExit(f'{number} ({hid}): bad hints')
        item['hints'] = hints
        words = []
        for w in data.get('words_meanings') or []:
            if isinstance(w, dict) and w.get('word') and w.get('meaning'):
                words.append({'word': w['word'], 'meaning': w['meaning']})
        item['words'] = words
        items.append(item)
    payload = {
        'source': 'HadeethEnc.com - Encyclopedia of Translated Prophetic '
                  'Hadiths (Arabic), https://hadeethenc.com',
        'api': 'https://hadeethenc.com/api/v1/hadeeths/one/?language=ar&id=<id>',
        'items': items,
    }
    Path(out).write_text(
        json.dumps(payload, ensure_ascii=False, indent=1) + '\n',
        encoding='utf-8', newline='\n')
    print(f'wrote {len(items)} hadith to {out}')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    main(sys.argv[1], sys.argv[2])
