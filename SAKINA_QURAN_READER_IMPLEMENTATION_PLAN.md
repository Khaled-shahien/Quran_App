# Sakina Quran reader implementation plan

Status values: `[ ]` Not Started · `[~]` In Progress · `[x]` Completed ·
`[!]` Blocked. Finding IDs (R1…) refer to `SAKINA_QURAN_READER_AUDIT.md`.
Branch: `ui-ux-transformation`, nothing committed.

## Design

**Three layouts, chosen in the reader's controls and remembered**
(`reading_layout`: `continuous` | `pages` | `verses`).

1. **Continuous (default).** One vertical scroll for the surah or wird. Text
   flows right-to-left, justified, with the end-of-ayah ornament inline. No
   card around the text; the page colour is the paper. A hairline with the
   mushaf page number marks each mushaf page boundary, so the reader always
   knows where they are in the printed mushaf. Each mushaf page is one lazily
   built paragraph, so Al-Baqarah does not lay out 56,000 characters at once.
2. **Mushaf pages.** One mushaf page per swipe, using the `page` field.
   Page *boundaries* are authentic; *line breaks* are not (the data has no
   line information). The mode is labelled accordingly.
3. **Verse by verse.** One verse per row with its number and one "more"
   button; no row of icons.

**Verse markers.** U+06DD followed by the verse number in Arabic-Indic
digits, in the Quran font: the font draws the ornament around the number.
It is text, so it flows and wraps like a word.

**Acting on a verse.** Long-press a verse in the flowing modes (or its
"more" button in verse mode) to select it and open a short sheet: play from
here, bookmark here, copy. The selected verse is tinted until the sheet
closes. Share, translation and tafsir are not offered: there is no share
dependency and no translation or tafsir data in the app.

**Header.** The surah title stays in the app bar. Inside the text, a surah
starts with a slim ornamental title band (wird ranges only) and the basmala
as plain centred Quran text, with no box. The duplicate basmala banner is
removed.

**Position.** Bookmarks gain an ayah number. An old bookmark that only has
a page index is converted once, by replaying the old 550-character
pagination to find the verse it pointed at. Last-read and wird positions
already use ayahs.

## Tasks

### Phase A — Continuous mode
- [x] A1 `reader_layout.dart`: `ReaderLayout` enum, `ayahEndMarker`, legacy page-index → ayah conversion (pure, tested)
- [x] A2 Group verses by mushaf page instead of 550 characters (R4)
- [x] A3 `QuranParagraph`: flowing text, inline ornament, recitation and selection tint, verse hit-testing (R2, R7)
- [x] A4 Continuous scroll with page markers, opening at the mushaf page of a target verse (R1, R6)
- [x] A5 Surah title band and unboxed basmala; remove the duplicate banner (R3, R9)
- [x] A6 Verse action sheet: play from here, bookmark here, copy (R7)
- [x] A7 Bookmark by ayah with one-time conversion of old bookmarks; search opens at the verse (R5)
- [x] A8 Layout picker in the reading controls; remove the whole-page press tint (R8)
- [~] A9 Emulator check: short and long surah, in the night and warm light designs. Sage and night-reading mode not checked on device

### Phase B — Verse-by-verse mode
- [x] B1 Lazy verse list with number, text and one "more" button
- [x] B2 Recitation follows the verse; last-read tracking
- [x] B3 Emulator check

### Phase C — Mushaf page mode
- [x] C1 Feasibility assessment against the data (documented in the audit, section 3)
- [x] C2 Paged view on authentic page boundaries, labelled in the controls as not line-exact
- [x] C3 Record what a line-exact mode would need

### Phase D — Verification
- [x] D1 Integrity test: every mode renders the source verses, in order, complete
- [x] D2 Update the reader tests to the new structure
- [x] D3 `flutter analyze`, full `flutter test`
- [x] D4 Screenshots; update this plan and the main development plan

### Phase E — Uthmanic font and fixed mushaf pages (2026-11-16, second pass)
- [!] E1 KFGQPC Uthmanic Hafs: blocked on the licence (written approval
  required). See `SAKINA_UTHMANIC_FONT_AUDIT.md`. Amiri Quran stays.
- [x] E2 `tool/check_quran_font.py`: character coverage of any font against
  the Quran text (Amiri Quran: 0 missing)
- [x] E3 Mushaf pages are fixed surfaces: horizontal `PageView` only, no
  vertical scrollable on a page, text sized to fit by measurement
  (`quran_page_layout.dart`), one span builder shared by drawing and
  measuring
- [x] E4 Slim page bar (about 56 px instead of 104 px) so pages keep more
  height; a small mark (tap for the explanation) when a page only fits below
  18 px
- [x] E5 Fixed: in a khatma wird, a mushaf page where one surah ends and the
  next begins was split into two pages with the same number
- [x] E6 Fixed: opening the bookmark from the side menu landed on the
  last-read position instead of the bookmark
- [x] E7 Tests: horizontal-only structure and gestures, every page fits on
  three phone sizes and landscape, 604-page fit report, all 114 surahs data
  integrity, bookmark restoration
- [~] E8 Emulator check on the latest build (details in the font audit,
  section 6, and `docs/reader-screenshots/README.md`); landscape not
  capturable on this emulator

## Decisions

1. **Font stays Amiri Quran.** It is a Quranic font with full coverage of
   this text and it draws the end-of-ayah ornament around Arabic-Indic
   digits. Moving to KFGQPC Uthmanic Hafs is the owner's licensing decision;
   the reader takes the family from one constant, `quranFontFamily`.
2. **Verse markers are text, not widgets:** U+06DD plus the number. A
   no-break space ties each marker to the last word of its verse.
3. **Markers use the text ink.** The accent colour was too pale on warm
   light paper (about 2.3:1).
4. **Verse numbers inside the ornament are always Arabic-Indic,** whatever
   the app's digit setting, because that is what the font encloses and what
   a mushaf prints. Page numbers in the interface follow the digit setting.
5. **Blocks follow mushaf pages** in every layout. The old 550-character
   pages are gone; the page layout's "page 3" is the mushaf's page.
6. **Free text selection was replaced by verse selection.** Long-press a
   verse (or its button in verse-by-verse) for: listen from here, bookmark
   here, copy. Copy gives the stored verse text and its reference, without
   the ornament.
7. **One basmala.** The banner above the reader is removed. Surahs 2–114
   show it once as an unboxed header line; Al-Fatiha keeps it as ayah 1;
   At-Tawbah has none (unchanged owner rule).
8. **Bookmarks store a verse.** An old bookmark is converted when it is
   opened, by replaying the old pagination (`legacyPageLeadAyah`, tested).
   Nothing stored is rewritten until the user saves a bookmark again.
9. **The whole-page press tint is removed;** only the selected or recited
   verse is tinted.
10. **Tests rewritten, not removed.** Paging and arrow tests now select the
    page layout; basmala tests check the same rules against the new widgets.

## Verification

- `flutter analyze`: no issues. `flutter test`: 680 passing (665 before).
- `reader_integrity_test`: for surahs 1, 9, 36 and 112 in the continuous
  and verse layouts, and all 286 verses of Al-Baqarah across its 48 mushaf
  pages in the page layout, the rendered verse strings equal the source
  strings, in order, and each marker is the verse's own number.
- `reader_layout_test`: layout names, Arabic-Indic digits, the marker, and
  the old-bookmark conversion.
- Emulator (Pixel 7 Pro, API 36): Al-Fatiha and Al-Baqarah in all three
  layouts in the night design; Al-Fatiha and Al-Baqarah continuous in warm
  light; the controls sheet; the verse action sheet; resuming at the last
  read page after reopening. Screenshots are in `docs/reader-screenshots/`.

## Fixed mushaf pages: how they fit

`fitQuranPage` measures a page with the same spans the screen draws, then
picks the largest text that fits with no scrolling: first the reader's own
size and spacing; then tighter lines (down to 1.6); then a smaller size, not
below 18 px unless the screen is too short, never below 12 px. Results are
cached per page, area and setting.

Measured over all 604 pages, default reading size 28 (see
`test/features/quran/presentation/widgets/quran_page_fit_test.dart`):

| Phone | Reading | Smallest size | Pages below 20 px | Pages below 18 px |
|---|---|---|---|---|
| Pixel 7 (411 x 914) | a surah | 22 | 0 | 0 |
| Pixel 7 | a wird across surahs | 19.5 | 1 | 0 |
| 360 x 780 | a surah | 18.25 | 51 | 0 |
| 360 x 780 | a wird | 15.5 | 120 | 13 (Juz Amma) |
| 360 x 640 | a surah | 15.5 | 564 | 180 |
| 360 x 640 | a wird | 12 | 566 | 236 |
| Pixel 7 landscape | Al-Baqarah | 22.5 | 0 | 0 |

On small phones the page layout reads small. Options for the owner: the
immersive mode already in the reading controls (hides both bars), the
continuous layout for larger text, or a two-page spread in landscape.

## Limitations and requirements for later

- **Mushaf line layout is not reproduced.** The page layout has authentic
  page boundaries and verse order; its lines wrap to the screen. A
  line-exact mode needs (a) word-by-word text with a line number per word
  for the chosen mushaf edition, and (b) either the KFGQPC QCF per-page
  fonts or a font designed for line justification, each with a licence that
  allows bundling. None of that is in the app today.
- **KFGQPC Uthmanic Hafs** needs written approval from the King Fahd
  Complex before it can be bundled.
- **The Quran text itself is still "pending owner review"** in
  `content_manifest.json`; this work displays it and does not vouch for it.
- **No share, translation or tafsir.** Sharing needs a share plugin (a new
  dependency); translation and tafsir need licensed data.
- **Opening at a verse lands on its mushaf page** in the continuous and
  page layouts (the verse may be a few lines down); verse-by-verse opens
  exactly at the verse.
- **Following recitation** in the continuous layout jumps when the recited
  verse moves to another mushaf page; it does not scroll smoothly.
- **Not checked on device:** a khatma wird that crosses surahs (covered by
  the title-band code path and tests only), night-reading mode, a sajda
  verse, landscape (emulator would not rotate; covered by a widget test).
- The JSON is still decoded on each open (audit R10); a shared in-memory
  copy would remove that cost.
