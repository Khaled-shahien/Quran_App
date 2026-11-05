import 'package:flutter/widgets.dart';

/// How numbers are shown: Western (0-9) or Arabic-Indic (٠-٩).
enum DigitStyle { western, arabic }

const List<int> _arabicIndicZero = [0x0660];

/// Converts Western digits in [text] for display. Data is never stored
/// converted; call this only when building a widget.
String applyDigitStyle(String text, DigitStyle style) {
  if (style == DigitStyle.western) return text;
  final zero = _arabicIndicZero.first;
  final out = StringBuffer();
  for (final unit in text.codeUnits) {
    out.writeCharCode(
      unit >= 0x30 && unit <= 0x39 ? zero + (unit - 0x30) : unit,
    );
  }
  return out.toString();
}

/// Makes the chosen digit style available to the widgets below it.
class DigitStyleScope extends InheritedWidget {
  const DigitStyleScope({super.key, required this.style, required super.child});

  final DigitStyle style;

  static DigitStyle of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DigitStyleScope>()?.style ??
      DigitStyle.western;

  @override
  bool updateShouldNotify(DigitStyleScope oldWidget) =>
      style != oldWidget.style;
}

extension DigitStyleContext on BuildContext {
  /// [text] with its digits in the user's chosen style.
  String digits(Object text) =>
      applyDigitStyle(text.toString(), DigitStyleScope.of(this));
}
