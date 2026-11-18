"""Builds assets/hadeath/hadeethenc_library.json, the full Arabic
HadeethEnc collection with its topics.

Usage:
  python -I -X utf8 tool/build_hadith_library.py <api_dir> <categories.json> <out.json>

<api_dir> holds `<id>.json` answers from
https://hadeethenc.com/api/v1/hadeeths/one/?language=ar&id=<id>; the
categories file is the answer of
https://hadeethenc.com/api/v1/categories/list/?language=ar.

Text fields are copied exactly as published. Translations lists and empty
fields are left out. The build fails on an answer that is not a hadith or
lacks its title, text or grade.
"""
import glob
import json
import os
import sys

TEXT = ('title', 'hadeeth', 'attribution', 'grade', 'explanation', 'reference')


def main(api_dir: str, categories: str, out: str) -> None:
    cats = json.load(open(categories, encoding='utf-8'))
    topics = []
    for c in cats:
        topics.append({
            'id': int(c['id']),
            'title': c['title'],
            'parent': int(c['parent_id']) if c.get('parent_id') else None,
        })
    known = {t['id'] for t in topics}
    items = []
    for path in sorted(glob.glob(os.path.join(api_dir, '*.json')),
                       key=lambda p: int(os.path.basename(p)[:-5])):
        data = json.load(open(path, encoding='utf-8'))
        if not isinstance(data, dict) or 'id' not in data:
            continue
        item = {'id': int(data['id'])}
        for field in TEXT:
            value = data.get(field)
            if not isinstance(value, str) or not value.strip():
                if field in ('title', 'hadeeth', 'grade'):
                    raise SystemExit(f'{data["id"]}: missing {field}')
                continue
            item[field] = value
        hints = [h for h in data.get('hints') or [] if isinstance(h, str) and h.strip()]
        if hints:
            item['hints'] = hints
        item['topics'] = sorted({int(c) for c in data.get('categories') or [] if str(c).isdigit() and int(c) in known})
        items.append(item)
    payload = {
        'source': 'HadeethEnc.com - Encyclopedia of Translated Prophetic '
                  'Hadiths (Arabic), https://hadeethenc.com',
        'topics': topics,
        'items': items,
    }
    with open(out, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(payload, f, ensure_ascii=False, separators=(',', ':'))
        f.write('\n')
    print(f'wrote {len(items)} hadith and {len(topics)} topics to {out}')


if __name__ == '__main__':
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)
    main(*sys.argv[1:])
