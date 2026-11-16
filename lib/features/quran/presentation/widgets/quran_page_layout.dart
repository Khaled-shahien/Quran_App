import 'package:flutter/painting.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/services/basmala.dart';
import '../../domain/services/reader_layout.dart';

/// Layout shared by drawing and measuring Quran text, so the fixed mushaf
/// page fits exactly what is drawn.

/// One verse as the reader shows it: the stored text and its number.
typedef QuranVerseText = ({String text, int number});

/// Verses set as one paragraph: each verse's span is the stored text,
/// followed by a separate span with its end-of-ayah ornament.
///
/// [ends] gives where each verse (with its ornament) ends in the plain
/// text, so a touch can be matched to a verse.
({TextSpan span, List<int> ends}) quranVersesSpan({
  required List<QuranVerseText> verses,
  required TextStyle style,
  required Color markerColor,
  required bool showMarkers,
  bool Function(int index)? isTinted,
  Color? tintColor,
}) {
  final List<InlineSpan> children = <InlineSpan>[];
  final List<int> ends = <int>[];
  int length = 0;
  for (int i = 0; i < verses.length; i++) {
    final QuranVerseText verse = verses[i];
    final bool tinted = isTinted?.call(i) ?? false;
    children.add(
      TextSpan(
        text: verse.text,
        style: tinted && tintColor != null
            ? TextStyle(backgroundColor: tintColor)
            : null,
      ),
    );
    length += verse.text.length;
    // A no-break space keeps the ornament on the line with the verse's
    // last word; an ordinary space after it lets the next verse wrap.
    final String tail = showMarkers ? ' ${ayahEndMarker(verse.number)} ' : ' ';
    children.add(
      TextSpan(
        text: tail,
        style: TextStyle(color: markerColor),
      ),
    );
    length += tail.length;
    ends.add(length);
  }
  return (span: TextSpan(style: style, children: children), ends: ends);
}

/// The basmala line above a surah's first verse.
abstract final class QuranBasmalaMetrics {
  static const double top = AppSpacing.sm;
  static const double bottom = AppSpacing.ms;

  static TextStyle style(TextStyle quran, double fontSize) =>
      quran.copyWith(fontSize: fontSize * 0.92, height: 1.7);
}

/// The title band of a surah that begins inside the text.
abstract final class QuranTitleMetrics {
  static const double marginTop = AppSpacing.md;
  static const double marginBottom = AppSpacing.xs;
  static const double padding = AppSpacing.sm;
  static const double border = 1;

  /// The small star at each end of the band.
  static const double ornament = 18;

  static TextStyle nameStyle(double fontSize, Color color) =>
      AppTypography.script.copyWith(
        fontSize: (fontSize * 0.82).clamp(20.0, 28.0),
        height: 1.3,
        color: color,
      );
}

/// One part of a mushaf page, for measuring.
sealed class QuranPagePiece {
  const QuranPagePiece();
}

/// A surah's title band (name and its one-line description).
final class QuranTitlePiece extends QuranPagePiece {
  const QuranTitlePiece({required this.name, required this.subtitle});
  final String name;
  final String subtitle;
}

/// The basmala line.
final class QuranBasmalaPiece extends QuranPagePiece {
  const QuranBasmalaPiece();
}

/// Consecutive verses set as one paragraph.
final class QuranVersesPiece extends QuranPagePiece {
  const QuranVersesPiece(this.verses);
  final List<QuranVerseText> verses;
}

/// The size a fixed mushaf page is drawn at.
typedef QuranPageFit = ({
  double fontSize,
  double lineHeight,

  /// True when the page only fits below the comfortable reading size.
  bool compressed,
});

/// Finds the largest text that lets [pieces] fit in [area] with no
/// scrolling, starting from the reader's own size and spacing.
///
/// Spacing is tightened before size: first the line height comes down to
/// [tightLineHeight], then the font size, never below [comfortableSize]
/// unless the page cannot fit otherwise (a very short screen, landscape),
/// and never below [minimumSize].
QuranPageFit fitQuranPage({
  required List<QuranPagePiece> pieces,
  required Size area,
  required TextStyle quranStyle,
  required TextStyle subtitleStyle,
  required Color markerColor,
  required bool showMarkers,
  required TextScaler textScaler,
  required double preferredSize,
  TextStyle? rootStyle,
  required double preferredLineHeight,
  double tightLineHeight = 1.6,
  double comfortableSize = 18,
  double minimumSize = 12,
}) {
  bool fits(double size, double lineHeight) =>
      measureQuranPage(
        pieces: pieces,
        width: area.width,
        quranStyle: quranStyle.copyWith(fontSize: size, height: lineHeight),
        subtitleStyle: subtitleStyle,
        markerColor: markerColor,
        showMarkers: showMarkers,
        textScaler: textScaler,
        rootStyle: rootStyle,
      ) <=
      area.height;

  if (fits(preferredSize, preferredLineHeight)) {
    return (
      fontSize: preferredSize,
      lineHeight: preferredLineHeight,
      compressed: false,
    );
  }

  final double tight = preferredLineHeight < tightLineHeight
      ? preferredLineHeight
      : tightLineHeight;

  // The reader's own size fits once the lines come closer together: keep
  // the size and the most generous spacing that still fits.
  if (fits(preferredSize, tight)) {
    double low = tight;
    double high = preferredLineHeight;
    for (int i = 0; i < 8; i++) {
      final double mid = (low + high) / 2;
      if (fits(preferredSize, mid)) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return (fontSize: preferredSize, lineHeight: low, compressed: false);
  }

  /// The largest size in [from]..[to] (quarter-point steps) that fits.
  double? largestFitting(double from, double to) {
    if (!fits(from, tight)) return null;
    double low = from;
    double high = to;
    while (high - low > 0.25) {
      final double mid = (low + high) / 2;
      if (fits(mid, tight)) {
        low = mid;
      } else {
        high = mid;
      }
    }
    return (low * 4).floorToDouble() / 4;
  }

  final double top = preferredSize < comfortableSize
      ? comfortableSize
      : preferredSize;
  final double? comfortable = largestFitting(comfortableSize, top);
  if (comfortable != null) {
    return (fontSize: comfortable, lineHeight: tight, compressed: false);
  }
  return (
    fontSize: largestFitting(minimumSize, comfortableSize) ?? minimumSize,
    lineHeight: tight,
    compressed: true,
  );
}

/// The height [pieces] take when laid out at [width].
double measureQuranPage({
  required List<QuranPagePiece> pieces,
  required double width,
  required TextStyle quranStyle,
  required TextStyle subtitleStyle,
  required Color markerColor,
  required bool showMarkers,
  required TextScaler textScaler,

  /// The ambient default text style. `Text` merges it into the root span it
  /// lays out, so measuring wraps each span the same way.
  TextStyle? rootStyle,
}) {
  final double fontSize = quranStyle.fontSize ?? 14;
  double height = 0;

  double layout(
    InlineSpan text, {
    required double maxWidth,
    int? maxLines,
    TextAlign align = TextAlign.start,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(style: rootStyle, children: <InlineSpan>[text]),
      textAlign: align,
      textDirection: TextDirection.rtl,
      textScaler: textScaler,
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);
    final double result = painter.height;
    painter.dispose();
    return result;
  }

  for (final QuranPagePiece piece in pieces) {
    switch (piece) {
      case QuranTitlePiece(:final name, :final subtitle):
        final double inner = width - 2 * QuranTitleMetrics.ornament;
        final double text =
            layout(
              TextSpan(
                text: name,
                style: QuranTitleMetrics.nameStyle(
                  fontSize,
                  quranStyle.color ?? const Color(0xFF000000),
                ),
              ),
              maxWidth: inner,
              maxLines: 1,
            ) +
            layout(
              TextSpan(text: subtitle, style: subtitleStyle),
              maxWidth: inner,
              maxLines: 1,
            );
        height +=
            QuranTitleMetrics.marginTop +
            QuranTitleMetrics.marginBottom +
            2 * QuranTitleMetrics.padding +
            2 * QuranTitleMetrics.border +
            (text > QuranTitleMetrics.ornament
                ? text
                : QuranTitleMetrics.ornament);
      case QuranBasmalaPiece():
        height +=
            QuranBasmalaMetrics.top +
            QuranBasmalaMetrics.bottom +
            layout(
              TextSpan(
                text: uthmaniBasmala,
                style: QuranBasmalaMetrics.style(quranStyle, fontSize),
              ),
              maxWidth: width,
              align: TextAlign.center,
            );
      case QuranVersesPiece(:final verses):
        height += layout(
          quranVersesSpan(
            verses: verses,
            style: quranStyle,
            markerColor: markerColor,
            showMarkers: showMarkers,
          ).span,
          maxWidth: width,
          align: TextAlign.justify,
        );
    }
  }
  return height;
}
