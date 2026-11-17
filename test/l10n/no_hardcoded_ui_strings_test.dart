import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// UI text belongs in `lib/l10n/app_ar.arb` (audit UX-03). Arabic string
/// literals left in presentation code are identifiers or content, each
/// listed here with its reason; anything new fails this test.
const Map<String, Set<String>> _allowed = {
  // Content keys: category names as they appear in the bundled adhkar.
  'lib/features/duas/presentation/screens/duas_screen.dart': {'أدعية قرآنية'},
  // Asset file names.
  'lib/features/onboarding/presentation/widgets/onboarding_page.dart': {
    'assets/images/المصحف.png',
    'assets/images/بسم الله الرحمن الرحيم.png',
  },
  // Image asset names (assets/images/<name>.png).
  'lib/features/onboarding/presentation/widgets/category_grid_widget.dart': {
    'الادعيه',
    'التسبيح_الالكتروني',
    'اسماء_الله_الحسني',
    'القران',
    'الاذكار',
    'الاحاديث',
    'الانبياء',
    'صفة_الصلاة',
    'اركان_الدين',
  },
  // A pattern matching Arabic-Indic digits.
  'lib/features/quran/presentation/screens/quran_search_screen.dart': {'[٠-٩]'},
  // Khatma range units, stored in saved plans: identifiers, not labels.
  'lib/features/quran/presentation/screens/surah_details_screen.dart': {
    'صفحة',
    'حزب',
    'ربع',
    'جزء',
  },
  // Arabic-Indic digits used for conversion.
  'lib/features/islamic_guide/presentation/widgets/guide_item_card.dart': {
    '٠١٢٣٤٥٦٧٨٩',
  },
};

/// Files whose literals are religious content, to move into gated assets
/// (task P2-05) rather than into the ARB file.
const Set<String> _contentFiles = {
  'lib/features/quran/presentation/screens/asma_al_husna_screen.dart',
};

final RegExp _arabicLiteral = RegExp(r"""(['"])([^'"\n]*[؀-ۿ][^'"\n]*)\1""");

void main() {
  test('no Arabic UI text is hard-coded in presentation code', () {
    final offenders = <String>[];
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.path.replaceAll(r'\', '/'))
        .where(
          (p) => p.contains('/presentation/') && !_contentFiles.contains(p),
        );
    for (final path in files) {
      final lines = File(path).readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        for (final match in _arabicLiteral.allMatches(lines[i])) {
          final literal = match.group(2)!;
          if (_allowed[path]?.contains(literal) ?? false) continue;
          offenders.add('$path:${i + 1}: $literal');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Move UI text into app_ar.arb');
  });
}
