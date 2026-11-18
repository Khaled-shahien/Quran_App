import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';

/// A Hijri date in the Umm al-Qura calendar.
typedef HijriDate = ({int year, int month, int day});

/// Converts with the user's Hijri offset (`hijri_offset_days`): the shown
/// Hijri date of a civil day is that of the day [offsetDays] later.
class HijriConverter {
  const HijriConverter({this.offsetDays = 0});

  final int offsetDays;

  /// Null outside the Umm al-Qura table (1356–1500 AH).
  HijriDate? of(DateTime civil) {
    try {
      final DateTime day = DateTime(
        civil.year,
        civil.month,
        civil.day + offsetDays,
      );
      final HijriCalendar h = HijriCalendar.fromDate(day);
      if (h.hMonth < 1 || h.hMonth > 12) return null;
      return (year: h.hYear, month: h.hMonth, day: h.hDay);
    } on ArgumentError {
      return null;
    }
  }

  /// The civil day shown as [year]/[month]/[day].
  DateTime civilOf(int year, int month, int day) {
    final DateTime g = HijriCalendar().hijriToGregorian(year, month, day);
    return DateTime(g.year, g.month, g.day - offsetDays);
  }

  int daysIn(int year, int month) =>
      HijriCalendar().getDaysInMonth(year, month);

  /// Every day of a Hijri month with its civil date.
  List<({int day, DateTime civil})> month(int year, int month) => [
    for (int d = 1; d <= daysIn(year, month); d++)
      (day: d, civil: civilOf(year, month, d)),
  ];
}

/// Whole calendar days from [a] to [b], unaffected by daylight saving.
int daysBetween(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// An occasion on fixed Hijri dates (or every month, e.g. the white days).
class IslamicOccasion {
  const IslamicOccasion({
    required this.id,
    required this.name,
    required this.from,
    required this.to,
    this.month,
    this.note,
  });

  final String id;
  final String name;

  /// Null for an occasion of every month.
  final int? month;
  final int from;
  final int to;
  final String? note;

  bool covers(int hijriMonth, int hijriDay) =>
      (month == null || month == hijriMonth) &&
      hijriDay >= from &&
      hijriDay <= to;
}

/// `assets/islamic_occasions.json`, read once.
class IslamicOccasions {
  IslamicOccasions({Future<String> Function()? load})
    : _load = load ?? (() => rootBundle.loadString(path));

  static const String path = 'assets/islamic_occasions.json';
  static final IslamicOccasions bundled = IslamicOccasions();

  final Future<String> Function() _load;
  List<IslamicOccasion>? _all;

  Future<List<IslamicOccasion>> all() async => _all ??= parse(await _load());

  static List<IslamicOccasion> parse(String raw) {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic> || decoded['schemaVersion'] != 1) {
      throw const FormatException('Unsupported occasions file');
    }
    IslamicOccasion read(Object? o, {required bool monthly}) {
      if (o case {
        'id': final String id,
        'name': final String name,
        'from': final int from,
        'to': final int to,
      } when from >= 1 && to >= from && to <= 30) {
        final Object? month = (o as Map)['month'];
        if (!monthly && (month is! int || month < 1 || month > 12)) {
          throw FormatException('Bad month for $id');
        }
        final Object? note = o['note'];
        return IslamicOccasion(
          id: id,
          name: name,
          from: from,
          to: to,
          month: monthly ? null : month as int,
          note: note is String ? note : null,
        );
      }
      throw const FormatException('Bad occasion');
    }

    return List.unmodifiable([
      for (final o in decoded['occasions'] as List<dynamic>)
        read(o, monthly: false),
      for (final o in (decoded['monthly'] as List<dynamic>?) ?? const [])
        read(o, monthly: true),
    ]);
  }

  /// The next start of each yearly occasion from [today] on (inclusive),
  /// soonest first, with the number of days until it.
  static List<({IslamicOccasion occasion, DateTime start, int days})> upcoming(
    List<IslamicOccasion> occasions,
    DateTime today,
    HijriConverter converter, {
    int limit = 6,
  }) {
    final HijriDate? now = converter.of(today);
    if (now == null) return const [];
    final DateTime day = DateTime(today.year, today.month, today.day);
    final List<({IslamicOccasion occasion, DateTime start, int days})> list =
        [];
    for (final IslamicOccasion o in occasions) {
      if (o.month == null) continue;
      for (final int year in [now.year, now.year + 1]) {
        DateTime start;
        try {
          start = converter.civilOf(year, o.month!, o.from);
        } catch (_) {
          continue;
        }
        final DateTime end = DateTime(
          start.year,
          start.month,
          start.day + o.to - o.from,
        );
        if (!end.isBefore(day)) {
          list.add((
            occasion: o,
            start: start,
            days: start.isBefore(day) ? 0 : daysBetween(day, start),
          ));
          break;
        }
      }
    }
    list.sort((a, b) => a.start.compareTo(b.start));
    return list.take(limit).toList();
  }
}
