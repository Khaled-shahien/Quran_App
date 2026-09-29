"""Exercise the actual gate CLIs with isolated, synthetic release fixtures."""
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys
import tempfile
import unittest

SCRIPTS = Path(__file__).resolve().parents[1]
COLLECTIONS = ('assets/quran_master.json', 'assets/quran_duas.json',
               'assets/prayers_data.json', 'assets/hadeath/ahadeth.txt')


class ReleaseGatesTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'scripts').mkdir()
        for name in ('verify_content.py', 'verify_release.py'):
            shutil.copyfile(SCRIPTS / name, self.root / 'scripts' / name)
        self.env = dict(os.environ, RELEASE_ANDROID_ID='org.fixture.sakina',
                        RELEASE_IOS_ID='org.fixture.sakina',
                        RELEASE_FIREBASE_PROJECT='fixture-project')
        self.manifest = {'schemaVersion': 1, 'approvalStatus': 'approved',
                         'collections': []}
        for name in COLLECTIONS:
            self.write(name, 'synthetic test content')
            self.manifest['collections'].append(dict(
                path=name, sha256=hashlib.sha256(b'synthetic test content').hexdigest(),
                source='Fixture reference', edition='1', license='Fixture license',
                reviewer='Fixture reviewer', approvalDate='2026-09-29',
                evidenceUrl='https://example.org/fixture-review'))
        self.save_manifest()
        self.write('android/app/build.gradle.kts',
                   'applicationId = "org.fixture.sakina"\n'
                   'signingConfig = signingConfigs.getByName("release")\n')
        self.write('android/app/google-services.json', json.dumps({
            'project_info': {'project_id': 'fixture-project'},
            'client': [{'client_info': {'android_client_info': {
                'package_name': 'org.fixture.sakina'}}}]}))
        self.write('ios/Runner/GoogleService-Info.plist', plistlib.dumps({
            'BUNDLE_ID': 'org.fixture.sakina', 'PROJECT_ID': 'fixture-project',
            'GOOGLE_APP_ID': 'fixture-app'}).decode())
        self.write('ios/Runner.xcodeproj/project.pbxproj',
                   'PRODUCT_BUNDLE_IDENTIFIER = org.fixture.sakina;\n')
                self.write('lib/firebase_options.dart', """
class DefaultFirebaseOptions {
    static const FirebaseOptions android = FirebaseOptions(
        projectId: 'fixture-project',
    );
    static const FirebaseOptions ios = FirebaseOptions(
        projectId: 'fixture-project',
        iosBundleId: 'org.fixture.sakina',
    );
}
""")

    def write(self, name, value):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value, encoding='utf-8')

    def save_manifest(self):
        self.write('content_manifest.json', json.dumps(self.manifest))

    def run_gate(self, script, *args):
        return subprocess.run([sys.executable, str(self.root / 'scripts' / script), *args],
                              env=self.env, capture_output=True, text=True)

    def assert_blocked(self, result):
        self.assertNotEqual(result.returncode, 0, result.stdout)
        self.assertNotIn('Traceback', result.stderr)

    def test_complete_synthetic_content_passes(self):
        result = self.run_gate('verify_content.py', '--require-approved')
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_empty_manifest_cannot_bypass_approval(self):
        self.manifest['collections'] = []
        self.save_manifest()
        self.assert_blocked(self.run_gate('verify_content.py', '--require-approved'))

    def test_missing_collection_cannot_bypass_integrity(self):
        self.manifest['collections'].pop()
        self.save_manifest()
        self.assert_blocked(self.run_gate('verify_content.py'))

    def test_duplicate_collection_is_rejected(self):
        self.manifest['collections'].append(self.manifest['collections'][0])
        self.save_manifest()
        self.assert_blocked(self.run_gate('verify_content.py'))

    def test_modified_content_is_rejected(self):
        self.write(COLLECTIONS[0], 'changed')
        self.assert_blocked(self.run_gate('verify_content.py'))

    def test_pending_approval_is_not_an_integrity_failure(self):
        self.manifest['approvalStatus'] = 'pending_owner_review'
        self.save_manifest()
        self.assertEqual(self.run_gate('verify_content.py').returncode, 0)
        self.assert_blocked(self.run_gate('verify_content.py', '--require-approved'))

    def test_whitespace_placeholder_is_rejected(self):
        self.manifest['collections'][0]['reviewer'] = ' pending_owner_review '
        self.save_manifest()
        self.assert_blocked(self.run_gate('verify_content.py', '--require-approved'))

    def test_invalid_manifest_is_a_controlled_failure(self):
        self.write('content_manifest.json', '{bad json')
        self.assert_blocked(self.run_gate('verify_content.py'))

    def test_matching_native_identity_passes(self):
        result = self.run_gate('verify_release.py')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('still require verification', result.stdout)

    def test_missing_owner_identity_is_rejected(self):
        self.env['RELEASE_ANDROID_ID'] = ''
        self.assert_blocked(self.run_gate('verify_release.py'))

    def test_commented_approved_id_cannot_mask_wrong_application_id(self):
        self.write('android/app/build.gradle.kts',
                   '// applicationId = "org.fixture.sakina"\n'
                   'applicationId = "org.wrong.app"\n')
        self.assert_blocked(self.run_gate('verify_release.py'))

    def test_debug_signing_is_rejected(self):
        self.write('android/app/build.gradle.kts',
                   'applicationId = "org.fixture.sakina"\n'
                   'signingConfig = signingConfigs.getByName("debug")\n')
        self.assert_blocked(self.run_gate('verify_release.py'))

    def test_missing_gradle_is_a_controlled_failure(self):
        (self.root / 'android/app/build.gradle.kts').unlink()
        self.assert_blocked(self.run_gate('verify_release.py'))

    def test_mismatched_firebase_project_is_rejected(self):
        self.env['RELEASE_FIREBASE_PROJECT'] = 'other-project'
        self.assert_blocked(self.run_gate('verify_release.py'))

    def test_incomplete_ios_configuration_is_rejected(self):
        self.write('ios/Runner/GoogleService-Info.plist', plistlib.dumps({}).decode())
        self.assert_blocked(self.run_gate('verify_release.py'))

        def test_mismatched_dart_firebase_options_are_rejected(self):
                self.write('lib/firebase_options.dart', """
class DefaultFirebaseOptions {
    static const FirebaseOptions android = FirebaseOptions(
        projectId: 'other-project',
    );
    static const FirebaseOptions ios = FirebaseOptions(
        projectId: 'fixture-project',
        iosBundleId: 'org.wrong.app',
    );
}
""")
                self.assert_blocked(self.run_gate('verify_release.py'))


if __name__ == '__main__':
    unittest.main()
