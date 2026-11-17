"""The coverage gate reads lcov and fails only below a floor."""
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / 'coverage_gate.py'


class CoverageGateTest(unittest.TestCase):
    LCOV = ('SF:lib/core/services/a.dart\nLF:10\nLH:5\nend_of_record\n'
            'SF:lib/features/prayers/b.dart\nLF:10\nLH:9\nend_of_record\n')

    def run_gate(self, lcov, floors):
        """Runs a copy of the gate whose FLOORS body is replaced by [floors]."""
        with tempfile.TemporaryDirectory() as tmp:
            text = SCRIPT.read_text(encoding='utf-8')
            text = re.sub(r'FLOORS = \{.*?\}', 'FLOORS = {' + floors + '}',
                          text, count=1, flags=re.S)
            script = Path(tmp) / 'coverage_gate.py'
            script.write_text(text, encoding='utf-8')
            report = Path(tmp) / 'lcov.info'
            report.write_text(lcov, encoding='utf-8')
            return subprocess.run([sys.executable, str(script), str(report)],
                                  capture_output=True, text=True)

    def test_reports_totals(self):
        result = self.run_gate(self.LCOV, '')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Total: 70.0%', result.stdout)

    def test_fails_below_a_floor(self):
        result = self.run_gate(self.LCOV, "'lib/core/services/': 60.0")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('lib/core/services/', result.stderr)

    def test_passes_at_the_floor(self):
        result = self.run_gate(self.LCOV, "'lib/core/services/': 50.0")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_windows_paths_match(self):
        lcov = 'SF:E:\\app\\lib\\core\\services\\a.dart\nLF:10\nLH:1\n'
        result = self.run_gate(lcov, "'lib/core/services/': 50.0")
        self.assertNotEqual(result.returncode, 0)

    def test_empty_report_fails(self):
        self.assertNotEqual(self.run_gate('', '').returncode, 0)

    def test_current_floors_are_set(self):
        self.assertRegex(SCRIPT.read_text(encoding='utf-8'),
                         r"'lib/core/services/': [1-9]")


if __name__ == '__main__':
    unittest.main()
