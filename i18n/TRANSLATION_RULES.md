# Translation rules (shared by all localizers)

You are a professional, native-level translator localizing the marketing / support /
privacy website for a premium iOS metronome app aimed at working musicians.

## Task
1. Read the English source: `i18n/en.json` (95 keys) in this same directory.
2. Translate every VALUE into natural, professional, native text for your target language.
   Keep every KEY exactly as-is.
3. Write valid JSON (UTF-8) to the output path you are given (`i18n/<slug>.json`).
4. Reply with only: `<slug>.json written, N keys`. Nothing else.

## Hard rules — follow exactly
- Output must be valid JSON with the IDENTICAL set of 95 keys as the source. Escape any
  double quotes inside values as `\"`. Do NOT wrap the JSON in markdown fences.
- Register: friendly-professional, for a premium consumer music app. Be consistent throughout.
  Avoid awkward machine-literal phrasing — write as a native marketer / technical writer would.
- App name "Metronome": where it is the app's PROPER name (page titles, "Metronome does not
  collect…"), render it the way the localized App Store listing for your language would — native
  script where that is the norm (CJK, Indic, Arabic/Hebrew), or keep Latin "Metronome" where that
  is conventional (most European languages). Where "metronome" is a COMMON noun (e.g. "the
  metronome musicians actually trust"), translate it as the ordinary word for a metronome.
- Keep these proper nouns unchanged: App Store, Apple Watch, Apple ID, iCloud, StoreKit,
  TestFlight, MIDI, Ableton Link, Bluetooth, Wi-Fi, VLAN, BPM, Live Activities, Lock Screen,
  Files app, Sound Library, Human Feel, Stage Mode, Pro, IDFA, IDFV, iOS, iPhone, iPad.
- Preserve inline HTML EXACTLY where present: `<code>…</code>` and `<strong>…</strong>` tags must
  remain. Translate prose OUTSIDE code, but DO NOT translate the literal UI menu paths / button
  labels INSIDE `<code>` tags (e.g. "All Settings → Delete All Data", "Restore Purchases",
  "iOS Settings → Metronome", "All Settings → BPM Controls → Volume Buttons = BPM",
  "All Settings → Latency Calibration") — keep those English verbatim.
- Preserve the HTML entity `&amp;` (renders as "&"), or replace with your language's natural
  word for "and" — either is fine. Preserve arrows →, em dashes —, ranges like 150–300, units
  (ms, kHz, %), musical notation (5/8, 7/8, 4/4, 3:2, 4:3, 5:4), ≤1 ms.
- Preserve email addresses and any URLs verbatim.
- `priv_last_updated`: translate the "Last updated:" label and render the date (April 27, 2026)
  naturally for your locale.
- Do NOT add, remove, or reorder keys.
