# Sakina Uthmanic font audit

Date: 2026-11-16. Question: can Sakina replace Amiri Quran with the official
KFGQPC Uthmanic Hafs font? **Answer: not yet. The font's licence requires
written approval from the King Fahd Glorious Quran Printing Complex, which
the project does not have.** Per the brief ("If licensing or compatibility
cannot be verified, stop the font replacement and report the blocker"), the
font was not downloaded, bundled or switched. Amiri Quran stays in use.

## 1. Current implementation (verified in code)

| Item | Finding |
|---|---|
| Quran font | Amiri Quran, `fonts/AmiriQuran-Regular.ttf`, family `AmiriQuran`, OFL 1.1, bundled unmodified (`fonts/AmiriQuran-OFL.txt`) |
| Where it is chosen | One constant, `quranFontFamily` in `lib/core/theme/app_typography.dart`; every piece of Quran text reads it |
| UI fonts | Cairo (interface) and Amiri (verses on cards, adhkar, surah titles); neither is used for the mushaf text |
| Quran text | `assets/quran_master.json`: 114 surahs, 6,236 verses, Tanzil Uthmani via AlQuran.cloud (`quran-uthmani`); manifest status "pending owner review" |
| Characters used | 69 code points (plus one invisible U+FEFF), including the Quranic marks U+06D6–U+06ED |
| Added for display | End-of-ayah sign U+06DD, Arabic-Indic digits U+0660–0669, no-break space U+00A0; never stored, never copied |

## 2. Glyph coverage, measured

New tool: `tool/check_quran_font.py <font>` reads the font's character map
(standard library only) and lists every character of the Quran text, and of
the display additions, that the font cannot draw.

| Font | Missing (text) | Missing (display additions) |
|---|---|---|
| Amiri Quran | **0 of 69** | **0** |
| Amiri (UI) | 0 of 69 | 0 |
| Cairo (UI) | **20 of 69** (U+06D6 onwards: the Quranic marks) | — |

Coverage is necessary, not sufficient: it does not prove marks are placed
well. Amiri Quran has also been checked visually on the emulator (section 6).
Cairo's result confirms it must never render Quran text.

## 3. KFGQPC Uthmanic Hafs: licence

- **Licence text shipped with the font** ("Uthmanic Script License"): the
  font is the Complex's property and "may not be reproduced, modified without
  the express written approval" of the Complex. Bundling the file in an app
  is reproduction. Source:
  <https://scancode-licensedb.aboutcode.org/kfgqpc-uthmanic-script-hafs.LICENSE>
- **Official developer site**: `https://qurancomplex.gov.sa/quran-dev/`
  returned *404 Not Found* on 2026-11-16, and the fonts site
  (`fonts.qurancomplex.gov.sa`) redirected to a page that also returned 404.
  The official download page and any current terms could not be read.
- **Third-party copies** (GitHub mirrors, font-download sites) exist. They
  were not used: the brief forbids unofficial or unverified files, and their
  licence labels ("freeware", "non-commercial") do not override the
  Complex's own terms.
- **Quran Foundation route**: its developer terms allow bundling mushaf fonts
  obtained through its API, only with an active Developer Console account,
  visible credit, and only inside the app. That needs an account and
  acceptance of their terms (an owner decision; the project's recitation work
  is already waiting on Quran Foundation credentials). Source:
  <https://api-docs.quran.foundation/legal/mushaf-fonts-and-images/>
- This is not legal advice; the owner should have the final terms reviewed.

**Status: blocked on written approval** (or on an owner decision to use the
Quran Foundation route). This matches the decision already on record for the
project: KFGQPC wanted, licence needs written approval, Amiri Quran interim.

## 4. KFGQPC Uthmanic Hafs: compatibility (not verifiable yet)

Without the official file, compatibility with `quran_master.json` cannot be
established. What has to be checked once a licensed copy is available:

1. **Character coverage**: run `tool/check_quran_font.py` on it.
2. **Encoding match**: the KFGQPC font is designed together with the
   Complex's own Hafs Unicode text. Tanzil's Uthmani text encodes some marks
   differently (for example how sukun-like and small-letter marks are
   written). Whether the font draws Tanzil's sequences correctly must be
   checked visually, verse by verse, for the passages in section 6.
3. **Ayah ornament**: confirm the font draws U+06DD around following
   Arabic-Indic digits (Amiri Quran does). If it uses a different
   convention, only the display-time marker in
   `lib/features/quran/domain/services/reader_layout.dart` changes; the
   text never does.
4. **If the font needs the Complex's own text** to render correctly, that is
   a data migration: it requires its own source verification, licence check
   and owner approval, and the integrity tests in
   `test/features/quran/domain/services/quran_data_integrity_test.dart`
   would be rerun against the new source. It must not be done as part of a
   font change.

## 5. Switching later (once approved)

1. Obtain written approval (or complete the Quran Foundation route).
2. Get the font from the official source; record version and checksum in
   `content_manifest.json` and `docs/THIRD_PARTY_ASSETS.md`.
3. Run `python tool/check_quran_font.py fonts/<file>.ttf`: must report 0.
4. Add it under `flutter: fonts:` in `pubspec.yaml`; keep `AmiriQuran`
   declared as the fallback.
5. Change `quranFontFamily` to the new family. Nothing else in the reader
   names a font.
6. Run the full test suite. The page-fit tests (`quran_page_fit_test`,
   `mushaf_pages_test`) re-measure all 604 pages with the new metrics.
7. Visual comparison against Amiri Quran on the emulator for the passages in
   section 6, all three layouts, all designs.

## 6. Visual check of the current font (Amiri Quran), latest build

Checked on the Android emulator (Pixel 7 Pro image, API 36) on the build
installed at 14:02 on 2026-11-16; screenshots in `docs/reader-screenshots/`
(files starting `v2-`):

- Al-Fatiha, Al-Baqarah, At-Tawbah, Yasin, Al-Ikhlas in the page layout;
  Al-Ikhlas also in continuous and verse-by-verse.
- Marks seen rendering correctly: harakat, shadda combinations, small high
  letters, madd, waqf signs (ۚ ۖ ۗ ۛ), the rub' el hizb ۞ (Al-Baqarah 177),
  the ayah ornament with Arabic-Indic numbers.
- Not seen: a sajda verse (no sajda page was opened).

A side-by-side Amiri Quran vs KFGQPC comparison (brief, phase 12) could not
be produced because the KFGQPC font cannot be used.
