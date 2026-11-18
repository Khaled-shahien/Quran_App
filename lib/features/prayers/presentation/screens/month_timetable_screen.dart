import 'package:sakina_app/features/settings/presentation/providers/digit_style_controller.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:sakina_app/core/accessibility/digit_style.dart';
import 'package:sakina_app/core/theme/app_spacing.dart';
import 'package:sakina_app/core/utils/hijri_calendar_data.dart';
import 'package:sakina_app/l10n/app_localizations.dart';
import 'package:sakina_app/l10n/localization.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/prayer_times_entity.dart';
import '../providers/prayer_times_provider.dart';

/// One day's row of the timetable.
typedef TimetableDay = ({DateTime date, PrayerTimesEntity times});

/// Column headers and the six times of a day, in order.
List<String> timetableTimes(PrayerTimesEntity t) => [
  t.fajr ?? '',
  t.sunrise ?? '',
  t.dhuhr ?? '',
  t.asr ?? '',
  t.maghrib ?? '',
  t.isha ?? '',
];

List<String> timetableHeaders(AppLocalizations l10n) => [
  l10n.monthTableDay,
  l10n.prayerTimesWidgetMessage8,
  l10n.prayerTimesPerformanceProviderMessage1,
  l10n.prayerTimesWidgetMessage9,
  l10n.prayerTimesWidgetMessage10,
  l10n.prayerTimesWidgetMessage11,
  l10n.prayerTimesWidgetMessage12,
];

/// Shares a file through the system sheet; replaced in tests.
typedef TimetableSharer = Future<void> Function(String path, String mime);

Future<void> _shareFile(String path, String mime) async {
  await SharePlus.instance.share(
    ShareParams(files: [XFile(path, mimeType: mime)]),
  );
}

/// The month's prayer times for the current place, computed on the phone,
/// with the Hijri date of each day; shared as an image or a PDF.
class MonthTimetableScreen extends StatefulWidget {
  const MonthTimetableScreen({
    super.key,
    this.share = _shareFile,
    this.folder = getTemporaryDirectory,
  });

  final TimetableSharer share;
  final Future<Directory> Function() folder;

  @override
  State<MonthTimetableScreen> createState() => _MonthTimetableScreenState();
}

class _MonthTimetableScreenState extends State<MonthTimetableScreen> {
  late DateTime _month;
  List<TimetableDay>? _days;
  bool _busy = false;
  final GlobalKey _table = GlobalKey();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    unawaited(_load());
  }

  Future<void> _load() async {
    final provider = context.read<PrayerTimesProvider>();
    setState(() => _days = null);
    final days = await provider.monthTimes(_month.year, _month.month);
    if (mounted) setState(() => _days = days);
  }

  void _shift(int months) {
    _month = DateTime(_month.year, _month.month + months);
    unawaited(_load());
  }

  int _hijriOffset() {
    try {
      return context.read<SharedPreferences>().getInt('hijri_offset_days') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  String _monthTitle(BuildContext context) =>
      context.digits(MaterialLocalizations.of(context).formatMonthYear(_month));

  Future<void> _run(Future<void> Function() work) async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final failed = l10nOf(context).monthTableShareFailed;
    try {
      await work();
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(failed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String> _file(String extension) async {
    final dir = await widget.folder();
    return '${dir.path}/sakina_timetable_${_month.year}_${_month.month}.$extension';
  }

  Future<void> _shareImage() => _run(() async {
    final boundary =
        _table.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) throw StateError('No image');
    final path = await _file('png');
    await File(path).writeAsBytes(data.buffer.asUint8List(), flush: true);
    await widget.share(path, 'image/png');
  });

  Future<void> _sharePdf() => _run(() async {
    final days = _days;
    if (days == null) return;
    final l10n = l10nOf(context);
    final digits = context.read<DigitStyleController?>()?.style;
    String d(String s) => digits == null ? s : applyDigitStyle(s, digits);
    final hijri = HijriConverter(offsetDays: _hijriOffset());
    final title = _monthTitle(context);
    final place = context.read<PrayerTimesProvider>().locationLabel;
    final font = pw.Font.ttf(await rootBundle.load('fonts/Amiri-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('fonts/Amiri-Bold.ttf'));
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: bold),
    );
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(24),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${l10n.monthTableTitle} - $title',
              style: const pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(place, style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: timetableHeaders(l10n),
              data: [
                for (final day in days)
                  [
                    d(_dayLabel(day.date, hijri)),
                    for (final t in timetableTimes(day.times)) d(t),
                  ],
              ],
              cellAlignment: pw.Alignment.center,
              headerStyle: const pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 2,
                horizontal: 4,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              l10n.monthTableFootnote,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ),
    );
    final path = await _file('pdf');
    await File(path).writeAsBytes(await doc.save(), flush: true);
    await widget.share(path, 'application/pdf');
  });

  /// "18 / 7" - the civil day and the Hijri day of the month.
  static String _dayLabel(DateTime date, HijriConverter hijri) {
    final h = hijri.of(date);
    return h == null ? '${date.day}' : '${date.day} / ${h.day}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = l10nOf(context);
    final theme = Theme.of(context);
    final days = _days;
    final hijri = HijriConverter(offsetDays: _hijriOffset());
    final today = DateTime.now();
    final place = context.watch<PrayerTimesProvider>().locationLabel;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.monthTableTitle),
        actions: [
          IconButton(
            key: const Key('month-share-image'),
            tooltip: l10n.monthTableShareImage,
            icon: const Icon(Icons.image_outlined),
            onPressed: days == null || _busy ? null : _shareImage,
          ),
          IconButton(
            key: const Key('month-share-pdf'),
            tooltip: l10n.monthTableSharePdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: days == null || _busy ? null : _sharePdf,
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: l10n.monthTablePrevious,
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => _shift(-1),
              ),
              Expanded(
                child: Text(
                  _monthTitle(context),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: l10n.monthTableNext,
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => _shift(1),
              ),
            ],
          ),
          Expanded(
            child: days == null
                ? const Center(child: CircularProgressIndicator())
                : days.isEmpty
                ? Center(child: Text(l10n.monthTableNoPlace))
                : SingleChildScrollView(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: RepaintBoundary(
                        key: _table,
                        child: Container(
                          color: theme.colorScheme.surface,
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$place · ${_monthTitle(context)}',
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              DataTable(
                                headingRowHeight: 40,
                                dataRowMinHeight: 32,
                                dataRowMaxHeight: 40,
                                columnSpacing: 14,
                                horizontalMargin: 8,
                                columns: [
                                  for (final h in timetableHeaders(l10n))
                                    DataColumn(label: Text(h)),
                                ],
                                rows: [
                                  for (final day in days)
                                    DataRow(
                                      selected:
                                          day.date.year == today.year &&
                                          day.date.month == today.month &&
                                          day.date.day == today.day,
                                      cells: [
                                        DataCell(
                                          Text(
                                            context.digits(
                                              _dayLabel(day.date, hijri),
                                            ),
                                          ),
                                        ),
                                        for (final t in timetableTimes(
                                          day.times,
                                        ))
                                          DataCell(Text(context.digits(t))),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                l10n.monthTableFootnote,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
