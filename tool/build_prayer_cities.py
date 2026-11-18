"""Builds assets/prayer_cities.json from GeoNames data (CC BY 4.0).

Usage: python -I -X utf8 build_cities.py <geonames_dir> <alt_dir> <countries_ar.json> <old_cities.json> <out.json> <app_zones.json>

app_zones.json lists tz.timeZoneDatabase.locations.keys of the app.

- Arab League countries: every city in cities15000 (population >= 15,000).
- Elsewhere: cities with population >= 100,000.
- IL and EH are left out (contested country labels; owner decision pending).
- Arabic names: GeoNames alternate names tagged 'ar' (preferred first, never
  historic or colloquial). No name is typed by hand; without a tagged
  Arabic name the city keeps its GeoNames name.
- The cities of the previous hand-checked list keep their Arabic names.
"""
import json
import math
import sys
from collections import defaultdict

geo_dir, alt_dir, countries_path, old_path, out_path = sys.argv[1:6]

ARAB = set('EG SA AE KW QA BH OM YE JO SY LB IQ PS SD LY TN DZ MA MR SO DJ KM'.split())
EXCLUDED = {'IL', 'EH'}
OTHER_MIN_POPULATION = 100_000

countries = json.load(open(countries_path, encoding='utf-8'))

rows = []
for line in open(f'{geo_dir}/cities15000.txt', encoding='utf-8'):
    f = line.rstrip('\n').split('\t')
    cc = f[8]
    pop = int(f[14] or 0)
    if cc in EXCLUDED:
        continue
    if cc not in ARAB and pop < OTHER_MIN_POPULATION:
        continue
    if cc not in countries:
        raise SystemExit(f'missing Arabic country name for {cc}')
    rows.append({
        'id': int(f[0]), 'name': f[1], 'ascii': f[2], 'lat': float(f[4]),
        'lon': float(f[5]), 'cc': cc, 'pop': pop, 'tz': f[17],
    })


import re

_ARABIC_NAME = re.compile(
    '^[\u0621-\u064A\u0660-\u0669\u064B-\u0652\u0670 ()\\-]+$')


def plausible_arabic(name):
    """Arabic letters only, no tripled letters, no doubled initial alef."""
    if not _ARABIC_NAME.match(name):
        return False
    if re.search(r'(.)\1\1', name) or name.startswith('\u0627\u0627'):
        return False
    return True

# Arabic names from the language-tagged alternate names.
arabic = defaultdict(list)
for cc in sorted(ARAB):
    for line in open(f'{alt_dir}/{cc}/{cc}.txt', encoding='utf-8'):
        f = line.rstrip('\n').split('\t')
        if len(f) < 8 or f[2] != 'ar':
            continue
        name = f[3].strip()
        preferred, short, colloquial, historic = (x == '1' for x in f[4:8])
        if colloquial or historic or not name or not plausible_arabic(name):
            continue
        arabic[int(f[1])].append((0 if preferred else 1, 0 if not short else 1, len(name), name))


# The usual Arabic names of a few capitals where GeoNames' tagged name
# drops the article or the epithet (GeoNames id -> name).
OVERRIDES = {
    379252: '\u0627\u0644\u062e\u0631\u0637\u0648\u0645',  # Khartoum
    2538475: '\u0627\u0644\u0631\u0628\u0627\u0637',  # Rabat
    109223: '\u0627\u0644\u0645\u062f\u064a\u0646\u0629 '
            '\u0627\u0644\u0645\u0646\u0648\u0631\u0629',  # Madinah
    285787: '\u0645\u062f\u064a\u0646\u0629 '
            '\u0627\u0644\u0643\u0648\u064a\u062a',  # Kuwait City
}

_HARAKAT = re.compile('[\u064B-\u0652\u0670]')


def best_arabic(gid):
    if gid in OVERRIDES:
        return OVERRIDES[gid]
    candidates = sorted(arabic.get(gid, []))
    # City names are shown without diacritics, like the rest of the list.
    return _HARAKAT.sub('', candidates[0][3]) if candidates else None


def distance_km(a_lat, a_lon, b_lat, b_lon):
    r = math.radians
    d_lat, d_lon = r(b_lat - a_lat), r(b_lon - a_lon)
    h = (math.sin(d_lat / 2) ** 2
         + math.cos(r(a_lat)) * math.cos(r(b_lat)) * math.sin(d_lon / 2) ** 2)
    return 2 * 6371.0088 * math.asin(min(1, math.sqrt(h)))


# Previous hand-checked list: its Arabic names win for the same city.
old = json.load(open(old_path, encoding='utf-8'))
old_by_english = {c['englishName'].lower(): c for c in old}

# Zones newer than the tz database bundled with the app (package
# timezone): each maps to an older zone with the same current offset.
# The build fails on any other zone the app cannot resolve.
ZONE_ALIASES = {
    'America/Ciudad_Juarez': 'America/Denver',
    'America/Punta_Arenas': 'America/Argentina/Buenos_Aires',
    'Asia/Atyrau': 'Asia/Aqtau',
    'Asia/Barnaul': 'Asia/Novosibirsk',
    'Asia/Qostanay': 'Asia/Aqtau',
    'Asia/Tomsk': 'Asia/Novosibirsk',
    'Asia/Yangon': 'Asia/Rangoon',
    'Europe/Astrakhan': 'Europe/Samara',
    'Europe/Kirov': 'Europe/Moscow',
    'Europe/Saratov': 'Europe/Samara',
    'Europe/Ulyanovsk': 'Europe/Samara',
}
app_zones = set(json.load(open(sys.argv[6], encoding='utf-8')))
for r in rows:
    r['tz'] = ZONE_ALIASES.get(r['tz'], r['tz'])
    if r['tz'] not in app_zones:
        raise SystemExit(f'zone {r["tz"]} unknown to the app tz database')
zones = sorted({r['tz'] for r in rows})
zone_index = {z: i for i, z in enumerate(zones)}
cities = []
kept_old = 0
tagged = 0
for r in sorted(rows, key=lambda r: (-r['pop'], r['id'])):
    name = None
    previous = old_by_english.get(r['ascii'].lower()) or old_by_english.get(r['name'].lower())
    if r['id'] in OVERRIDES:
        name = OVERRIDES[r['id']]
        if previous:
            old_by_english.pop(previous['englishName'].lower(), None)
    elif previous and distance_km(r['lat'], r['lon'], previous['latitude'], previous['longitude']) < 30:
        name = previous['name']
        kept_old += 1
        old_by_english.pop(previous['englishName'].lower(), None)
    if name is None and r['cc'] in ARAB:
        name = best_arabic(r['id'])
        if name:
            tagged += 1
    cities.append([
        name or r['name'],
        r['ascii'] if r['ascii'] != (name or r['name']) else '',
        r['cc'],
        round(r['lat'], 4),
        round(r['lon'], 4),
        zone_index[r['tz']],
        r['pop'],
    ])

# Any city of the old list that GeoNames did not match is kept as it was.
for c in old_by_english.values():
    cc = next((k for k, v in countries.items() if v == c['country']), None)
    if cc is None or c['timezone'] not in zone_index:
        raise SystemExit(f'cannot keep old city {c["englishName"]}')
    cities.append([c['name'], c['englishName'], cc, c['latitude'], c['longitude'],
                   zone_index[c['timezone']], 0])

out = {
    'schemaVersion': 2,
    'source': 'GeoNames (www.geonames.org), CC BY 4.0: cities15000 and '
              'Arabic-tagged alternate names, downloaded 2026-11-18',
    'columns': ['name', 'latinName', 'country', 'latitude', 'longitude',
                'zone', 'population'],
    'countries': {k: countries[k] for k in sorted({c[2] for c in cities})},
    'zones': zones,
    'cities': cities,
}
with open(out_path, 'w', encoding='utf-8', newline='\n') as fh:
    json.dump(out, fh, ensure_ascii=False, separators=(',', ':'))
    fh.write('\n')
arab_rows = [c for c in cities if c[2] in ARAB]
print(f'cities {len(cities)} (arab {len(arab_rows)}, arabic-named {kept_old + tagged}, '
      f'old kept {kept_old}), zones {len(zones)}, countries {len(out["countries"])}')
