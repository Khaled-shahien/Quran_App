"""Fail closed until owners supply an approved platform/Firebase identity matrix."""
import json
import os
import plistlib
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
expected = {key: os.getenv(key, '') for key in (
    'RELEASE_ANDROID_ID', 'RELEASE_IOS_ID', 'RELEASE_FIREBASE_PROJECT')}
errors = []
for key, value in expected.items():
    if not value.strip() or value != value.strip() or value.startswith('com.example') or 'YOUR_' in value:
        errors.append(f'{key} needs an approved production value')

try:
    gradle = (root / 'android/app/build.gradle.kts').read_text(encoding='utf-8')
    # Inspect assignments, not an approved ID mentioned only in a comment.
    gradle = re.sub(r'/\*.*?\*/', '', gradle, flags=re.S)
    ids = re.findall(r'^\s*applicationId\s*=\s*"([^"]+)"', gradle, flags=re.M)
    if ids != [expected['RELEASE_ANDROID_ID']]:
        errors.append('Android applicationId differs from approved identity')
    if re.search(r'signingConfig\s*=\s*signingConfigs.getByName\(\s*"debug"\s*\)', gradle):
        errors.append('Release must not use debug signing')
except (OSError, ValueError) as error:
    errors.append(f'Missing or invalid Android build configuration ({type(error).__name__})')

try:
    android = json.loads((root / 'android/app/google-services.json').read_text(encoding='utf-8'))
    if android['project_info']['project_id'] != expected['RELEASE_FIREBASE_PROJECT']:
        errors.append('Android Firebase project mismatch')
    packages = [item['client_info']['android_client_info']['package_name'] for item in android['client']]
    if expected['RELEASE_ANDROID_ID'] not in packages:
        errors.append('Android Firebase package mismatch')
    with (root / 'ios/Runner/GoogleService-Info.plist').open('rb') as stream:
        ios = plistlib.load(stream)
    if ios.get('BUNDLE_ID') != expected['RELEASE_IOS_ID'] or ios.get('PROJECT_ID') != expected['RELEASE_FIREBASE_PROJECT']:
        errors.append('iOS Firebase identity mismatch or placeholder')
    if not ios.get('GOOGLE_APP_ID') or 'YOUR_' in str(ios):
        errors.append('iOS Firebase configuration is incomplete')
    xcode = (root / 'ios/Runner.xcodeproj/project.pbxproj').read_text(encoding='utf-8')
    ids = re.findall(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);', xcode)
    app_ids = [value.strip('"') for value in ids if 'RunnerTests' not in value]
    if not app_ids or any(value != expected['RELEASE_IOS_ID'] for value in app_ids):
        errors.append('Xcode application bundle identity mismatch')
except (OSError, ValueError, KeyError, TypeError, AttributeError, plistlib.InvalidFileException) as error:
    errors.append(f'Missing or invalid platform configuration ({type(error).__name__})')

if errors:
    raise SystemExit('Release blocked:\n- ' + '\n- '.join(errors))
print('Native identity checks passed. Signing, Firebase Dart options and device evidence still require verification.')
