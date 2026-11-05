import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakina_app/features/quran/domain/services/basmala.dart';

/// Runs against the real bundled Quran text, so any change to the asset
/// that would break the split is caught here.
void main() {
  final List<dynamic> quran =
      jsonDecode(File('assets/quran_master.json').readAsStringSync())
          as List<dynamic>;

  String ayahText(int surah, int ayah) =>
      (quran[surah - 1]['ayahs'] as List<dynamic>)[ayah - 1]['text'] as String;

  test('the header text is exactly Al-Fatiha 1:1 of the bundled text', () {
    expect(ayahText(1, 1).replaceAll('﻿', ''), uthmaniBasmala);
  });

  test('every surah except 1 and 9 gets a header, losslessly', () {
    for (var surah = 2; surah <= 114; surah++) {
      if (surah == 9) continue;
      final original = ayahText(surah, 1);
      final split = splitLeadingBasmala(
        surahNumber: surah,
        ayahNumber: 1,
        text: original,
      );

      expect(split.hasBasmala, isTrue, reason: 'surah $surah');
      expect(split.ayahText, isNotEmpty, reason: 'surah $surah');
      expect(
        original.endsWith(' ${split.ayahText}'),
        isTrue,
        reason: 'surah $surah: only the leading basmala may be removed',
      );
      expect(
        original.length - split.ayahText.length,
        uthmaniBasmala.length + (surah == 95 || surah == 97 ? 2 : 1),
        reason: 'surah $surah: nothing else is removed',
      );
    }
  });

  test('Al-Fatiha keeps the basmala as its numbered first ayah', () {
    final split = splitLeadingBasmala(
      surahNumber: 1,
      ayahNumber: 1,
      text: ayahText(1, 1),
    );
    expect(split.hasBasmala, isFalse);
    expect(split.ayahText, ayahText(1, 1));
  });

  test('At-Tawbah has no basmala header and its text is untouched', () {
    final split = splitLeadingBasmala(
      surahNumber: 9,
      ayahNumber: 1,
      text: ayahText(9, 1),
    );
    expect(split.hasBasmala, isFalse);
    expect(split.ayahText, ayahText(9, 1));
  });

  test('ayahs other than the first are never touched', () {
    // An-Naml 27:30 contains the basmala inside the ayah.
    final text = ayahText(27, 30);
    expect(text, contains(uthmaniBasmala));
    final split = splitLeadingBasmala(
      surahNumber: 27,
      ayahNumber: 30,
      text: text,
    );
    expect(split.hasBasmala, isFalse);
    expect(split.ayahText, text);
  });

  test('a text that is only the basmala is not emptied', () {
    final split = splitLeadingBasmala(
      surahNumber: 2,
      ayahNumber: 1,
      text: uthmaniBasmala,
    );
    expect(split.hasBasmala, isFalse);
    expect(split.ayahText, uthmaniBasmala);
  });
}
