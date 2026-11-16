part of '../surah_details_screen.dart';

/// Identifies one verse across surahs.
typedef _VerseRef = ({int surah, int ayah});

/// Reading settings shared by every piece of Quran text on the screen.
@immutable
class _ReaderStyle {
  const _ReaderStyle({
    required this.fontSize,
    required this.lineHeight,
    required this.textColor,
    required this.markerColor,
    required this.tintColor,
    required this.showMarkers,
  });

  final double fontSize;
  final double lineHeight;
  final Color textColor;

  /// The end-of-ayah ornament and its number.
  final Color markerColor;

  /// Behind the verse being recited or acted on.
  final Color tintColor;
  final bool showMarkers;

  TextStyle get text => TextStyle(
    fontFamily: quranFontFamily,
    fontSize: fontSize,
    color: textColor,
    height: lineHeight,
  );

  _ReaderStyle copyWith({double? fontSize, double? lineHeight}) => _ReaderStyle(
    fontSize: fontSize ?? this.fontSize,
    lineHeight: lineHeight ?? this.lineHeight,
    textColor: textColor,
    markerColor: markerColor,
    tintColor: tintColor,
    showMarkers: showMarkers,
  );
}

/// Consecutive verses set as one flowing, justified paragraph, each followed
/// by its end-of-ayah ornament.
///
/// The verse text is drawn exactly as stored. The ornament is added here
/// for display only.
class _QuranParagraph extends StatefulWidget {
  const _QuranParagraph({
    required this.verses,
    required this.style,
    required this.highlighted,
    required this.onVerseLongPress,
  });

  final List<_SurahVerseData> verses;
  final _ReaderStyle style;

  /// Verses to tint: the one being recited and the one being acted on.
  final Set<_VerseRef> highlighted;
  final ValueChanged<_SurahVerseData> onVerseLongPress;

  @override
  State<_QuranParagraph> createState() => _QuranParagraphState();
}

class _QuranParagraphState extends State<_QuranParagraph> {
  final GlobalKey _textKey = GlobalKey();

  /// Where each verse's span ends in the paragraph's plain text, so a touch
  /// can be matched to a verse.
  List<int> _ends = const <int>[];

  TextSpan _buildSpan() {
    final List<_SurahVerseData> verses = widget.verses;
    final built = quranVersesSpan(
      verses: <QuranVerseText>[
        for (final _SurahVerseData verse in verses)
          (text: verse.text, number: verse.verseNumber),
      ],
      style: widget.style.text,
      markerColor: widget.style.markerColor,
      showMarkers: widget.style.showMarkers,
      tintColor: widget.style.tintColor,
      isTinted: (i) => widget.highlighted.contains((
        surah: verses[i].surahNumber,
        ayah: verses[i].verseNumber,
      )),
    );
    _ends = built.ends;
    return built.span;
  }

  _SurahVerseData? _verseAt(Offset globalPosition) {
    final RenderObject? render = _textKey.currentContext?.findRenderObject();
    if (render is! RenderParagraph) return null;
    final int offset = render
        .getPositionForOffset(render.globalToLocal(globalPosition))
        .offset;
    for (int i = 0; i < _ends.length; i++) {
      if (offset < _ends[i]) return widget.verses[i];
    }
    return widget.verses.isEmpty ? null : widget.verses.last;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: (details) {
        final _SurahVerseData? verse = _verseAt(details.globalPosition);
        if (verse != null) widget.onVerseLongPress(verse);
      },
      child: Text.rich(
        _buildSpan(),
        key: _textKey,
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
      ),
    );
  }
}

/// The basmala above a surah's first verse: plain centred Quran text.
class _BasmalaLine extends StatelessWidget {
  const _BasmalaLine({required this.surahNumber, required this.style});

  final int surahNumber;
  final _ReaderStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: Key('surah-basmala-$surahNumber'),
      padding: const EdgeInsets.only(
        top: QuranBasmalaMetrics.top,
        bottom: QuranBasmalaMetrics.bottom,
      ),
      child: Text(
        uthmaniBasmala,
        textAlign: TextAlign.center,
        textDirection: TextDirection.rtl,
        style: QuranBasmalaMetrics.style(style.text, style.fontSize),
      ),
    );
  }
}

/// The title of a surah that begins inside the text (a wird that crosses
/// surahs): its name between two ornamental rules.
class _SurahTitleBand extends StatelessWidget {
  const _SurahTitleBand({
    required this.verse,
    required this.subtitle,
    required this.style,
  });

  final _SurahVerseData verse;
  final String subtitle;
  final _ReaderStyle style;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color rule = style.markerColor.withValues(alpha: 0.45);
    return Semantics(
      header: true,
      child: Container(
        key: Key('surah-header-${verse.surahNumber}'),
        margin: const EdgeInsets.only(
          top: QuranTitleMetrics.marginTop,
          bottom: QuranTitleMetrics.marginBottom,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: QuranTitleMetrics.padding,
        ),
        decoration: BoxDecoration(
          border: Border.symmetric(horizontal: BorderSide(color: rule)),
        ),
        child: Row(
          children: [
            _RuleEnd(color: rule),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    verse.surahName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: QuranTitleMetrics.nameStyle(
                      style.fontSize,
                      style.textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            _RuleEnd(color: rule),
          ],
        ),
      ),
    );
  }
}

/// A small eight-pointed star closing each end of the title band.
class _RuleEnd extends StatelessWidget {
  const _RuleEnd({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: QuranTitleMetrics.ornament,
        child: CustomPaint(painter: _StarPainter(color)),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final Offset center = size.center(Offset.zero);
    final double side = size.shortestSide * 0.62;
    final Rect square = Rect.fromCenter(
      center: center,
      width: side,
      height: side,
    );
    canvas.drawRect(square, paint);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(0.785398);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawRect(square, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.color != color;
}

/// A hairline carrying the mushaf page number, shown where a mushaf page
/// ends in the continuous view.
class _PageMarker extends StatelessWidget {
  const _PageMarker({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Color rule = color.withValues(alpha: 0.28);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.ms),
      child: Row(
        children: [
          Expanded(child: Divider(color: rule)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.ms),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Divider(color: rule)),
        ],
      ),
    );
  }
}

/// One verse on its own row, for study: the verse with its end-of-ayah
/// ornament, and a single button that opens the verse's actions.
class _VerseRow extends StatelessWidget {
  const _VerseRow({
    required this.verse,
    required this.style,
    required this.tinted,
    required this.onActions,
    required this.actionsTooltip,
  });

  final _SurahVerseData verse;
  final _ReaderStyle style;
  final bool tinted;
  final VoidCallback onActions;
  final String actionsTooltip;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.base),
      curve: AppMotion.standard,
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.ms,
        AppSpacing.xs,
        0,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tinted ? style.tintColor : Colors.transparent,
        borderRadius: AppRadius.controls,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPress: onActions,
              child: Text.rich(
                TextSpan(
                  style: style.text,
                  children: [
                    TextSpan(text: verse.text),
                    if (style.showMarkers)
                      TextSpan(
                        text: '\u00A0${ayahEndMarker(verse.verseNumber)}',
                        style: TextStyle(color: style.markerColor),
                      ),
                  ],
                ),
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
              ),
            ),
          ),
          IconButton(
            tooltip: actionsTooltip,
            onPressed: onActions,
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// A lazily built list that can open at any item: [anchor] sits at the top
/// of the viewport and items are built outwards from it in both directions.
///
/// Reports the item at the top of the viewport as the user scrolls.
class _AnchoredList extends StatefulWidget {
  const _AnchoredList({
    super.key,
    required this.itemCount,
    required this.anchor,
    required this.itemBuilder,
    required this.onTopItemChanged,
    required this.padding,
  });

  final int itemCount;
  final int anchor;
  final IndexedWidgetBuilder itemBuilder;
  final ValueChanged<int> onTopItemChanged;
  final EdgeInsets padding;

  @override
  State<_AnchoredList> createState() => _AnchoredListState();
}

class _AnchoredListState extends State<_AnchoredList> {
  final GlobalKey _centerKey = GlobalKey();
  final ScrollController _controller = ScrollController();
  final Map<int, GlobalKey> _itemKeys = <int, GlobalKey>{};
  int? _reported;

  @override
  void didUpdateWidget(_AnchoredList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.anchor != widget.anchor ||
        oldWidget.itemCount != widget.itemCount) {
      _itemKeys.clear();
      _reported = null;
      // Offset zero is the anchor item's top edge.
      if (_controller.hasClients) _controller.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _item(BuildContext context, int index) {
    final GlobalKey key = _itemKeys.putIfAbsent(index, GlobalKey.new);
    return KeyedSubtree(key: key, child: widget.itemBuilder(context, index));
  }

  /// The last built item whose top edge is at or above the viewport's top.
  bool _reportTopItem(ScrollNotification notification) {
    final RenderObject? viewport = context.findRenderObject();
    if (viewport is! RenderBox) return false;
    int? top;
    int? firstBuilt;
    _itemKeys.removeWhere((_, key) => key.currentContext == null);
    for (final MapEntry<int, GlobalKey> entry in _itemKeys.entries) {
      final RenderObject? box = entry.value.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      final double dy = box.localToGlobal(Offset.zero, ancestor: viewport).dy;
      if (firstBuilt == null || entry.key < firstBuilt) firstBuilt = entry.key;
      if (dy <= widget.padding.top + 1 && (top == null || entry.key > top)) {
        top = entry.key;
      }
    }
    final int? current = top ?? firstBuilt;
    if (current != null && current != _reported) {
      _reported = current;
      widget.onTopItemChanged(current);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final int anchor = widget.itemCount == 0
        ? 0
        : widget.anchor.clamp(0, widget.itemCount - 1);
    final EdgeInsets padding = widget.padding;
    return NotificationListener<ScrollNotification>(
      onNotification: _reportTopItem,
      child: CustomScrollView(
        controller: _controller,
        center: _centerKey,
        slivers: [
          // Items before the anchor, built upwards from it.
          SliverPadding(
            padding: EdgeInsets.only(left: padding.left, right: padding.right),
            sliver: SliverList.builder(
              itemCount: anchor,
              itemBuilder: (context, i) => _item(context, anchor - 1 - i),
            ),
          ),
          SliverPadding(
            key: _centerKey,
            padding: EdgeInsets.fromLTRB(
              padding.left,
              padding.top,
              padding.right,
              padding.bottom,
            ),
            sliver: SliverList.builder(
              itemCount: widget.itemCount - anchor,
              itemBuilder: (context, i) => _item(context, anchor + i),
            ),
          ),
        ],
      ),
    );
  }
}
