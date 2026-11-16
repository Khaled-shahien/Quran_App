# Sakina Quran reader audit

Audit date: 2026-11-16. Scope: `lib/features/quran/presentation/screens/surah_details_screen.dart`
and its four part files, the Quran data, the fonts, and the reader tests.

## 1. How the reader works today

- **Data.** `assets/quran_master.json`: 114 surahs, 6,236 ayahs. Each ayah has
  `text`, `numberInSurah`, `page` (1–604), `juz`, `hizbQuarter`, `manzil`,
  `ruku`, `sajda`. The manifest lists it as Tanzil Uthmani text via
  AlQuran.cloud (`quran-uthmani`), **pending owner review**.
- **Characters.** 70 distinct code points: Arabic letters, harakat, and the
  Quranic annotation marks U+06D6–U+06ED. There is no end-of-ayah sign
  (U+06DD) in the data; verse numbers come from `numberInSurah`. One stray
  U+FEFF (byte-order mark) exists in the text; it is invisible and was left
  alone.
- **Font.** Quran text uses `AmiriQuran` (Amiri Quran, OFL, bundled
  unmodified). It is an interim choice: the owner wants KFGQPC Uthmanic
  Hafs, whose licence needs written approval.
- **Loading.** The screen reads and decodes the whole JSON file each time it
  opens, then keeps either one surah or, for a khatma wird, every ayah whose
  page, hizb or juz falls in the wird's range (this can cross surahs).
- **Basmala.** `splitLeadingBasmala` removes the basmala from ayah 1 of
  surahs 2–114 (never 9) so it can be shown as an unnumbered header; in
  Al-Fatiha it stays as ayah 1. This is an owner decision and is tested.
- **Pagination.** Verses are packed into "pages" of about 550 characters.
  These pages have no relation to the mushaf.
- **Rendering.** A horizontal `PageView`; each page is a bordered, shadowed
  card holding one `SelectableText.rich`, justified, with a round bordered
  badge (`WidgetSpan`) after every verse.
- **Position.** The last read ayah is saved per surah. The bookmark saves a
  surah and a *page index* into the 550-character pages. A khatma wird
  saves surah, ayah, mushaf page and page index.
- **Audio.** `RecitationController.playSurah(surah, fromAyah:)`; the ayah
  being recited gets a background tint and the reader turns to its page.
- **Controls.** A sheet for size (22–38), line height (1.5–2.5), night
  reading, verse markers on/off, and an immersive mode.

## 2. Problems

| # | Finding | Priority |
|---|---|---|
| R1 | The text sits in a card with a border and shadow inside page margins: roughly 64 px of every row is chrome, and short surahs leave most of the card empty | P1 |
| R2 | Verse markers are round bordered badges built as widgets. They are larger than the text's x-height, break the line rhythm, and are not the Quranic end-of-ayah ornament | P1 |
| R3 | The basmala shows twice: a banner above the pages plus the in-text header (surahs 2–114), and a banner plus ayah 1 in Al-Fatiha | P1 |
| R4 | Pages are cut every ~550 characters, so "page 3 of 12" means nothing to someone who knows the mushaf | P1 |
| R5 | The bookmark stores an index into those arbitrary pages, so it only means something under that exact pagination. Search also passes a *mushaf* page number where the reader expects a page *index* (harmless today only because the verse it passes alongside wins) | P1 |
| R6 | There is one way to read: no continuous scroll and no verse-by-verse view | P1 |
| R7 | Selection is free text selection only; there is no way to act on a verse (play from here, bookmark here, copy with its reference) | P1 |
| R8 | The whole page tints on any touch (`_pagePressed`), which reads as a glitch while scrolling | P2 |
| R9 | The basmala header and banner use boxed containers; the surah header inside a wird is another shadowed card | P2 |
| R10 | The 4.4 MB JSON is re-read and re-decoded on every open | P2 |

## 3. What the data supports for a mushaf page mode

| Need | Available? |
|---|---|
| Which mushaf page each ayah is on (page boundaries) | **Yes** — `page`, 1–604, the Madinah mushaf numbering |
| Juz, hizb quarter, ruku, sajda positions | Yes |
| Which *line* each word is on (15 lines per page) | **No** |
| Word-by-word text | **No** — text is stored per ayah |
| Per-page glyph fonts (KFGQPC QCF v1/v2) or a line-justified font with its line data | **No**, and they carry their own licence terms |

So the app can show exactly the verses that belong to each mushaf page, in
order, with authentic page boundaries. It cannot reproduce the printed
page's line breaks: lines wrap wherever the screen width puts them. A mode
built on this must say so and must not be presented as a facsimile.

## 4. Fonts

| Font | Uthmani marks | Ayah-number ornament | Licence | Status |
|---|---|---|---|---|
| Amiri Quran | Complete for this data | U+06DD encloses following Arabic-Indic digits | OFL 1.1, bundled | In use |
| KFGQPC Uthmanic Hafs | Complete; the Madinah mushaf's own hand | Yes | King Fahd Complex terms; redistribution needs written approval | Wanted by owner, blocked on licence |
| KFGQPC QCF page fonts (v1/v2) | Per-page glyph fonts, needed for line-exact pages | Yes | Same body; plus word-level data | Not available |
| Cairo, Amiri (UI) | Not Quranic fonts | — | OFL | Never used for Quran text |

Decision for this work: keep Amiri Quran. Switching fonts is a licensing
decision for the owner, and the reader reads the family from one constant
(`quranFontFamily`), so a later switch is a one-line change plus a visual
check. The licence position was re-checked on 2026-11-16; see
`SAKINA_UTHMANIC_FONT_AUDIT.md`.

## 5. Tests that describe required behaviour

- `surah_reader_basmala_test`: basmala as an unnumbered header for surah 2,
  none for surah 9, numbered ayah 1 in Al-Fatiha; Quran font and saved size;
  large text never shrunk.
- `last_read_position_test`: reopening resumes at the last page; a khatma
  range keeps its own start and saves nothing.
- `reader_direction_test`: in the paged view, previous is on the right with
  `chevron_right`, next on the left with `chevron_left`.
- `night_reading_test`: night reading colours and contrast.
- `surah_details_screen_test`: title, revelation place, bookmark saving.
- `basmala_test`, `quran_search_test`: text handling, untouched.

## 6. Integrity rules for this work

- The reader never edits verse text. Everything shown comes from
  `quran_master.json` through the existing `splitLeadingBasmala`.
- Verse numbers come from `numberInSurah`. The ornament is the Unicode
  end-of-ayah sign followed by the number in Arabic-Indic digits, added at
  display time only; it is never written back or copied as part of a verse.
- Copy gives the verse text exactly as stored, followed by its reference.
- A test compares what each mode renders against the source for whole
  surahs: same verses, same order, no missing or repeated text.

## 7. Second audit (2026-11-16)

| # | Finding | Status |
|---|---|---|
| R11 | The page layout let a long page scroll vertically, so it was not a fixed page | Fixed: pages are measured and fitted, no vertical scrolling |
| R12 | In a wird, a surah starting mid-page split that mushaf page into two "pages" with the same number | Fixed: grouping is by page number only (`groupByMushafPage`) |
| R13 | The side menu's bookmark opened the surah at the last-read position, not at the bookmark | Fixed: it now asks the reader to open at the bookmark |
| R14 | The page bar took about 104 px of a fixed page's height | Reduced to about 56 px |
| R15 | The basmala header always shows the canonical form even where the source's ayah 1 uses the variant with a shadda on the ba | Unchanged (existing owner rule); recorded for the owner |
