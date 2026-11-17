# Bundled fonts and city coordinates

- Cairo variable font: [Google Fonts source](https://github.com/google/fonts/tree/main/ofl/cairo),
  SIL Open Font License in `fonts/Cairo-OFL.txt`.
- Amiri regular and bold: [Google Fonts source](https://github.com/google/fonts/tree/main/ofl/amiri),
  SIL Open Font License in `fonts/Amiri-OFL.txt`.
- Amiri Quran regular (Quran text in the reader): [Google Fonts source](https://github.com/google/fonts/tree/main/ofl/amiriquran),
  unmodified, SIL Open Font License in `fonts/AmiriQuran-OFL.txt`.
  SHA-256 `e2a47644762d16bdfb6d33e0d8db8c6ff30beae84150ef5a705316bbd829455c`.
  Interim choice until written permission to bundle KFGQPC Uthmanic Hafs is obtained.
- `assets/prayer_cities.json`: selected city centers retrieved 2026-09-28 from
  the [Open-Meteo Geocoding API](https://open-meteo.com/en/docs/geocoding-api),
  using GeoNames data. Data is redistributed under
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
  The bundled subset retains Arabic names, English search names, countries and
  coordinates, plus each city's IANA timezone (retrieved 2026-11-05 from the
  same API) so prayer times are calculated offline in the city's local time.
  It is not an exhaustive city database. No user search requests
  are sent to this geocoding service at runtime.
- `assets/images/الانبياء.png`, `صفة_الصلاة.png`, `اركان_الدين.png`: home
  category icons generated on 2026-11-16 with Canva's image generator from the
  owner's Canva account, using the app's Duas icon as a style reference, then
  background removed in Canva. Use is subject to Canva's terms for generated
  content.
- `android/app/src/main/res/raw/adhan_*.mp3`: four adhan recordings supplied
  directly by the app owner as MP3 files and bundled unchanged (byte-identical
  copies). Source: user-provided. Licence and redistribution rights: **pending
  verification**; no licence is claimed for them. Original filenames and
  details in `ADHAN_AUDIO_LIBRARY.md`.

These licenses and attributions do not certify the religious content. Its separate
manifest retains pending review status until the source owner supplies evidence.
