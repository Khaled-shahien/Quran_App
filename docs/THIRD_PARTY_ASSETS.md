# Bundled fonts and city coordinates

- Cairo variable font: [Google Fonts source](https://github.com/google/fonts/tree/main/ofl/cairo),
  SIL Open Font License in `fonts/Cairo-OFL.txt`.
- Amiri regular and bold: [Google Fonts source](https://github.com/google/fonts/tree/main/ofl/amiri),
  SIL Open Font License in `fonts/Amiri-OFL.txt`.
- `assets/prayer_cities.json`: selected city centers retrieved 2026-09-28 from
  the [Open-Meteo Geocoding API](https://open-meteo.com/en/docs/geocoding-api),
  using GeoNames data. Data is redistributed under
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
  The bundled subset retains Arabic names, English search names, countries and
  coordinates; it is not an exhaustive city database. No user search requests
  are sent to this geocoding service at runtime.

These licenses and attributions do not certify the religious content. Its separate
manifest retains pending review status until the source owner supplies evidence.
