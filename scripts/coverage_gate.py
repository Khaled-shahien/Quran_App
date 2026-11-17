"""Report line coverage from lcov.info and fail when a critical area drops.

Usage: python3 scripts/coverage_gate.py coverage/lcov.info

Coverage is a report, not a target: the floors only stop the notification,
background and prayer code from silently losing tests. Raise a floor when
coverage there improves; never lower one to make a change pass.
"""
import sys
from pathlib import Path

# Path prefix -> minimum line coverage (percent). Set just below the value
# measured when the floor was introduced (2026-11-17: services 45.7 %,
# prayers 79.2 %, total 70.0 %).
FLOORS = {
    'lib/core/services/': 44.0,
    'lib/features/prayers/': 77.0,
}


def parse(path):
    files = {}
    current = None
    for line in Path(path).read_text(encoding='utf-8').splitlines():
        if line.startswith('SF:'):
            current = line[3:].replace(chr(92), '/')  # Windows paths
            files[current] = [0, 0]
        elif line.startswith('LF:') and current:
            files[current][0] = int(line[3:])
        elif line.startswith('LH:') and current:
            files[current][1] = int(line[3:])
    return files


def area(files, prefix):
    found = hit = 0
    for name, (lf, lh) in files.items():
        if prefix in name:
            found += lf
            hit += lh
    return (100.0 * hit / found) if found else 0.0, found


def main(argv):
    if len(argv) != 2:
        raise SystemExit(__doc__)
    files = parse(argv[1])
    total_found = sum(lf for lf, _ in files.values())
    total_hit = sum(lh for _, lh in files.values())
    if not total_found:
        raise SystemExit('No coverage data found')
    print(f'Total: {100.0 * total_hit / total_found:.1f}% '
          f'({total_hit}/{total_found} lines in {len(files)} files)')
    failed = []
    for prefix, floor in FLOORS.items():
        percent, found = area(files, prefix)
        print(f'{prefix}: {percent:.1f}% of {found} lines (floor {floor:.1f}%)')
        if percent < floor:
            failed.append(f'{prefix} {percent:.1f}% < {floor:.1f}%')
    if failed:
        raise SystemExit('Coverage dropped below the floor: ' + '; '.join(failed))


if __name__ == '__main__':
    main(sys.argv)
