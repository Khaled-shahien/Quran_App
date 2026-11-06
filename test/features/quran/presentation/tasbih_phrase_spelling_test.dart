import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/l10n/app_localizations.dart';

// Built from code points so the expected text cannot be mistyped.
final alhamdulillah = String.fromCharCodes([
  0x627, 0x644, 0x62D, 0x645, 0x62F, 0x20, 0x644, 0x644, 0x647, //
]);
final laIlahaIllallah = String.fromCharCodes([
  0x644, 0x627, 0x20, 0x625, 0x644, 0x647, 0x20, 0x625, 0x644, 0x627, 0x20,
  0x627, 0x644, 0x644, 0x647, //
]);

void main() {
  test('built-in tasbih phrases use the standard spelling', () {
    final l10n = lookupAppLocalizations(const Locale('ar'));
    expect(l10n.tasbeehScreenMessage2, alhamdulillah);
    expect(l10n.tasbeehScreenMessage3, laIlahaIllallah);
  });
}
