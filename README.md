# CKS Slavia Mobile

A Flutter application for CKS Slavia members with:
- Training tracking
- Weightlifting competition calendar
- Sinclair calculator
- User profile and authentication
- Push notifications
- Calendar events with Google Calendar integration

## 🚀 Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## GitHub Releases (APK)

Workflow [`.github/workflows/release.yml`](.github/workflows/release.yml) buduje **release APK** i dołącza plik do GitHub Release po wypchnięciu tagu w formacie `v*.*` lub `v*.*.*` (np. `git tag v1.0.1 && git push origin v1.0.1`).

Artefakt domyślny: `build/app/outputs/flutter-apk/app-release.apk` — strona klubu może linkować do najnowszego release przez API (patrz `NUXT_PUBLIC_MOBILE_GITHUB_REPO` w repozytorium frontendu).

## Backend i katalogi

Aplikacja mobilna łączy się z tym samym API co WWW (`../Slavia-backend`).

- Katalogi (presety motywu, odznaki): `GET /api/system/*` przy starcie
- Logika lokalna: `lib/utils/sinclair.dart`, `badge_helpers.dart`, `weightlifting_ratios.dart`
- Test wektorowy Sinclair: `flutter test test/sinclair_vector_test.dart`

Domyślny URL API: `lib/config/brand_defaults.dart` (nadpisanie: `--dart-define=SLAVIA_API_BASE=...`).

## Spójność z frontendem (WWW)

- Motyw domyślny **Slavia** (zieleń + slate) i font **Outfit** — zbliżone do strony Nuxt ([produkcja](https://cksslavia.vercel.app/)).
- W menu **☰ (Więcej)** → **„Strona klubu”** domyślnie otwiera **https://cksslavia.vercel.app/** (bez dodatkowej konfiguracji).

Inny adres (np. staging):

```bash
flutter run --dart-define=SLAVIA_WEB_URL=https://twoja-preview.vercel.app
```

## Profil zawodnika — statystyki i wykresy

- Lista **Zawodnicy** → tap na kartę otwiera **pełny profil** (`AthleteDetailScreen`): PB z zawodów, Sinclair, starty, wykres progresu dwuboju (zatwierdzone zawody), opcjonalnie **zawody vs trening** + siatka insightów (realizacja formy, trend 90 dni, PB w serii…) — zgodnie z logiką profilu na stronie.
- **Panel zawodnika** → zakładka **Przegląd** korzysta z tego samego widoku.
- Menu **☰** → **„Moje wykresy i statystyki”** (gdy konto ma `athlete_id`).
