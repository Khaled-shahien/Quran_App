# Phase 4 – research notes (2026-11-18)

Items of Phase 4 that were not built, what each would need, and the decision
each waits for. Nothing here was downloaded or added to the app. Licence
statements below are to be confirmed with each rights holder before any use;
none has been verified with them.

## 1. Word-by-word meanings, iʿrab and fixed mushaf pages (G5, G6)

| Need | Candidate sources | What it involves | Open question for the owner |
|---|---|---|---|
| Fixed mushaf pages (the printed Madinah layout, line for line) | KFGQPC page fonts (one font per page, as used by Quran.com) | 604 font files plus per-page glyph data; a page renderer instead of the reflowing reader | Written permission from the King Fahd Complex for bundling the fonts (the same request as the Uthmanic Hafs font already pending) |
| Word-by-word meanings (Arabic) | Quran Foundation API word data; Quranic Arabic Corpus (corpus.quran.com) | A word index for 77,000+ words, a tap-a-word sheet in the reader | QF API needs the same client registration and backend as R-16; the Corpus is published under the GNU GPL, which would bind the app's licence |
| Grammar (iʿrab) | Quranic Arabic Corpus (morphology and syntax for every word); printed iʿrab works (e.g. al-Jadwal fi Iʿrab al-Quran) | Morphology tags shown per word; full iʿrab prose needs a licensed book text | Whether a GPL dependency is acceptable; or a licence for a printed iʿrab |
| Tajweed colouring | Tajweed-annotated texts published by some Quran APIs | Rule markup per letter, colour legend, a font that keeps marks aligned | Licence and provenance of the annotations; a scholar's check of the rules |

Recommendation: decide the KFGQPC request first; it unblocks both the font
already wanted and fixed pages. Treat the Corpus as a separate licence
decision.

## 2. Retrieval-only semantic search and voice commands (roadmap 6.4)

- **Semantic search.** It would only point to texts already in the app (verses,
  tafsir, hadith), never generate text. It needs an on-device multilingual
  embedding model (tens of MB) or a precomputed index of the bundled texts
  plus a small query encoder. The open questions are Arabic quality and the
  size budget (the APK is already over 80 MB). A spike should measure
  retrieval quality on a set of Arabic queries before anything is built. The
  keyword search across all sources (R-54) is in the app.
- **Voice commands** (not approved this phase). The phone's speech service may
  send audio to Google, which needs a privacy-policy disclosure and an opt-in.

## 3. Account-free sync

| Option | How | Privacy | Effort |
|---|---|---|---|
| Encrypted export to the user's own cloud folder (in the app) | Export with a passphrase (R-53), saved anywhere the user picks | The file is AES-256-GCM encrypted; we hold no account | Done |
| Scheduled encrypted export | Android Storage Access Framework: the user picks a folder once (e.g. a Drive folder); the app writes a new encrypted copy weekly. iOS: a file in the app's iCloud Documents container | Same file format; the passphrase is needed on the phone to write | Medium. The passphrase must be stored in the Android Keystore / iOS Keychain, or entered each time |
| Phone to phone | Show the backup as a sequence of codes or send it over local Wi-Fi between two phones | Never leaves the two phones | Medium–high; needs QR or network permissions |
| Real sync (two devices in use) | Merge per record with timestamps (the database rows already carry `updated_at`) | Needs a storage target; conflict rules for the log and hifz | High |

Recommendation: the scheduled encrypted export to a folder the user picks. It
reuses the export format and the encryption, needs no server and no
account, and covers changing phones. Real two-way sync is not worth the risk
yet.

## 4. Not started at the owner's choice this phase

- Wear OS tile (G21): a separate module and Play listing, and a watch to test.
- QR codes for the group khatma: the text codes in the app would fit in a QR
  once a QR package (and, for scanning, the camera permission) is approved.
