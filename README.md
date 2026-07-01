# Jyotira (ज्योतिरा) — Vedic Astrology & Kundli
 
A premium, multilingual Vedic astrology app for Android (Flutter). The chart is
**100% deterministic astronomy**; AI is used only to *narrate* the computed
facts — it never invents planetary positions, so predictions are reproducible,
not random.
 
> Name note: "Jyotira" (from *Jyoti*, light) was chosen for memorability.
> **Verify trademark/Play Store availability before launch.** Alternates:
> Grahaa, Shubhdin, Divyaastra.
 
## What's deterministic vs. AI
- **Deterministic (no AI, no randomness):** ascendant/lagna, planetary signs &
  nakshatras, whole-sign houses, Vimshottari mahadasha, and the 36-point
  Ashtakoota (Guna Milan) compatibility score. Same input → identical output,
  every time.
- **AI (narration only):** daily guidance, full report, dosha & remedies,
  muhurat themes, compatibility explanation, and "Ask AI Jyotish" — all
  generated from the deterministic chart facts via a server you control.
 
## Architecture
- **Flutter + Riverpod + go_router.**
- **Swiss Ephemeris (`sweph`)** with Lahiri ayanamsa for the chart engine
  (`lib/features/kundli/domain/kundli_engine.dart` — the single native-binding
  file).
- **RevenueCat (`purchases_flutter`)** for subscriptions (Google Play Billing).
- **Serverless backend** (`server/interpret.ts`) holds the Anthropic key,
  caches by chart hash, and uses a cheap model for daily / stronger models for
  paid long-form reports → low, predictable token cost.
- Languages: English, Hindi, Tamil, Telugu, Bengali, Marathi.
 
## Monetization
- **Free:** daily guidance + basic kundli (chart, planets, dasha).
- **Premium (subscription):** full report, dosha & remedies, compatibility
  reasoning, Ask AI Jyotish, muhurat. Gated via RevenueCat entitlement
  `premium`.
 
---
 
## Build the APK
 
> A compiled APK is **not** committed here — it must be built with the Flutter
> + Android toolchain (multi-GB SDKs). Two supported paths:
 
### Option A — GitHub Actions (no local setup)
1. Push this project to a GitHub repo (branch `main`).
2. Open the **Actions** tab → **Build APK** → **Run workflow**, optionally
   entering your `API_BASE_URL` and RevenueCat key.
3. Download the **`jyotira-debug-apk`** artifact and install
   `app-debug.apk` on a device (enable "install unknown apps").
 
### Option B — Local build
Requires Flutter (stable) + Android SDK.
```bash
flutter create --org com.jyotira --project-name jyotira --platforms=android .
flutter pub get
flutter gen-l10n
flutter build apk --debug \
  --dart-define=API_BASE_URL=https://your-app.vercel.app/api \
  --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
# Output: build/app/outputs/flutter-apk/app-debug.apk
```
For a release build: `flutter build appbundle --release` (configure signing in
`android/app/build.gradle` first).
 
---
 
## What you must supply
1. **Backend deploy** — deploy `server/interpret.ts` (see `server/README.md`)
   and set `ANTHROPIC_API_KEY`. Pass its URL via `--dart-define=API_BASE_URL`.
2. **RevenueCat** — create products/offerings and an entitlement named
   `premium`; pass the Android public key via `--dart-define`.
3. **Ephemeris files** — for max precision add Swiss Ephemeris `.se1` files to
   `assets/ephe/` (the app runs without them on the bundled fallback). Review
   Swiss Ephemeris licensing for commercial use.
4. **Trademark / store name check** for "Jyotira".
 
The app builds and runs without (1) and (2); network features show a friendly
"not configured" state until set.
 
## Verify the one native binding
`sweph` is a native port; its Dart method/enum names are the only API in this
project tied to the bundled C library. After `flutter pub get`, confirm the
calls in `kundli_engine.dart` (`Sweph.init`, `swe_calc_ut`, `swe_houses_ex`,
`SiderealMode.SE_SIDM_LAHIRI`, `Hsys.W`) match the resolved package version.
 
## Play Store requirements (before publishing)
- **Privacy policy** (birth date/time/place are personal data) and an in-app
  **data deletion** path — already present in Settings.
- Declare data collection in the Play Console Data Safety form.
- Add app icons and a release signing key.
- Astrology content is "for guidance/entertainment"; avoid medical, legal, or
  financial guarantees (the server prompt already enforces this).
 
## Project layout
```
lib/
  main.dart, app/router.dart
  core/        config, theme, network, payments, prefs, widgets
  features/
    kundli/    domain (engine, models, guna_milan), data, application, presentation
    reading/   reusable premium reading screen
    compat/    Guna Milan UI
    ask/       Ask AI chat
    home/ paywall/ settings/
  l10n/        app_en/hi/ta/te/bn/mr.arb
assets/
  data/cities_in.json     offline city → lat/lng/tz
  ephe/                   Swiss Ephemeris data (.se1) go here
server/
  interpret.ts            grounded LLM endpoint
.github/workflows/build-apk.yml
```
