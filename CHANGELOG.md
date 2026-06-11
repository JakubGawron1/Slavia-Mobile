# Changelog — Slavia Mobile

## [0.9.111+111] — 2026-06-11 (tag `v0.9.111`)

### Nowe funkcje
- **Trener AI** — ekran czatu z asystentem (`AiCoachScreen`), markdown jak na WWW.
- **Składki członkowskie** — wspólny ekran płatności dla zawodnika i trenera.
- **Ekran zbanowanego konta** — przekierowanie po 403 z flagą banu.
- **Ranking publiczny** i **wyzwania klubowe** — parity z witryną WWW.
- **go_router** — trasy `/`, `/login`, `/banned`, `/browser-panel`, `/chat`, `/notifications`.
- **FCM (fundament)** — stub `FcmService`; polling powiadomień bez regresji.

### Ulepszenia
- **Panel admin/SA** — usunięte ekrany WWW-only; konto bez roli Athlete/Trainer → `BrowserPanelScreen`.
- **API** — podział `api_service` na moduły; flagi nawigacji panelu z backendu.
- **Motywy** — presety z `@slavia/shared` (`theme_preset_catalog`).
- **Hub treningowy / klubowy** — przebudowa nawigacji modułów (Fala 3).

### Instalacja
Pobierz APK z [GitHub Releases](https://github.com/JakubGawron1/Slavia-Mobile/releases) (tag `v0.9.111`) lub zsynchronizuj wydanie w panelu admina witryny.

---

## [1.0.1+11] - 2026-05-19 (tag `v1.0.1-dev`)

### Naprawione
- **Analiza sztangi** — nakładka toru na odtwarzaczu wideo; odświeżanie statusu Premium po wczytaniu (`barbell_premium_service`).

### Ulepszenia
- **Aktualność (szczegóły)** — przycisk udostępniania wpisu (share sheet) z haptyką.
- **Starty zawodników (kadra)** — pull-to-refresh oraz czytelniejsze puste stany i błąd sieci.

### Instalacja
Pobierz APK z [GitHub Releases](https://github.com/JakubGawron1/Slavia-Mobile/releases) (tag `v1.0.1-dev`) lub zsynchronizuj wydanie w panelu admina witryny.

---


## [0.9.10+10] — 2026-05-19 (tag `v0.9.10-dev`)

### Nowe funkcje
- **2FA (TOTP)** — drugi krok logowania z kodem z aplikacji authenticator (`totp_code`), jak na stronie WWW.
- **Motywy eksperymentalne** — presety `glass`, `sport-tech`, `neon-brutalism` zsynchronizowane z frontendem.
- **Analiza sztangi** — tor rysowany na wideo podczas odtwarzania; gęstsze próbkowanie klatek ML Kit (do 72).
- **Skaner QR obecności** — pełnoekranowa kamera z ramką, narożnikami i animowaną linią skanowania.

### Ulepszenia
- **Wydajność startu** — `Selector` / `AuthAppearanceSync` ograniczają niepotrzebne przebudowy `MaterialApp`.
- **Android signing** — opcjonalny release keystore z env (`ANDROID_KEYSTORE_*`); dokumentacja `docs/android-signing.md`.
- **CI** — workflow Release APK obsługuje sekret `ANDROID_KEYSTORE_BASE64` dla spójnego podpisu.

### Instalacja
Pobierz APK z [GitHub Releases](https://github.com/JakubGawron1/Slavia-Mobile/releases) (tag `v0.9.10-dev`) lub zsynchronizuj wydanie w panelu admina witryny.

---

## [0.9.6+7] — 2026-05-18 (tag `v0.9.6-dev`)

### Nowe funkcje
- **Analiza sztangi (MVP)** — wstępna ocena techniki podnoszenia na podstawie wideo/klatek.
- **Nawigacja** — przeprojektowany dolny pasek na **4 zakładki** (`NavigationBar` + `IndexedStack`).

### Ulepszenia
- **Aktualizator APK** — fallback przy nieudanej instalacji (ponowna próba / alternatywna ścieżka otwarcia instalatora).
- **Wydania GitHub** — obsługa **prerelease** przy sprawdzaniu aktualizacji; czytelniejsze komunikaty po sync z API.

### Instalacja
Pobierz APK z [GitHub Releases](https://github.com/JakubGawron1/Slavia-Mobile/releases) (tag `v0.9.6-dev`) lub zsynchronizuj wydanie w panelu admina witryny.

---

## [0.9.5+6] — 2026-05-18 (tag `v0.9.5-dev`)

### Nowe funkcje
- **Obecność QR** — skaner w menu; zatwierdzona obecność po skanie kodu z sali (`/api/attendance/qr-checkin`).
- **Czat** — status „Na żywo” rozmówcy, reakcje emoji (👍 ✅ 🔥 💪), ping presence co 60 s.
- **Udostępnianie wyniku** — eksport karty PNG ze share sheet (`ResultShareService`) z osi czasu zawodnika.
- **Powiadomienia** — osobne kanały Android: `slavia_club` / `slavia_chat` wg typu push.

### Ulepszenia
- **Sesja** — token i dane logowania w `flutter_secure_storage` (`SecureCredentialsStore`).
- **Wydajność** — batch Sinclair w `compute()` (isolate); cache SWR (`PersistentApiCache`, `auth/me`).
- **Aktualizator APK** — `versionCode` z liczby commitów + kodu z `pubspec`; lepsze komunikaty po instalatorze.
- **Zależności** — `local_auth` 3, `flutter_timezone` 5, `share_plus`, `flutter_secure_storage`.

### Naprawki
- Instalacja APK z poziomu aplikacji (uprawnienia, URI, komunikat po powrocie z instalatora).
- Biometria i strefa czasowa powiadomień po major upgrade pakietów.

### Instalacja
Pobierz APK z [GitHub Releases](https://github.com/JakubGawron1/Slavia-Mobile/releases) (tag `v0.9.5-dev`) lub zsynchronizuj wydanie w panelu admina witryny.

---

## [0.9.1+2] — 2026-05-15

### Naprawki
- **Instalacja APK z aplikacji** — usunięto `FLAG_ACTIVITY_NEW_TASK` przy otwieraniu instalatora (częsty powód „pakiet się nie instaluje”). Dodano `grantUriPermission` dla obsługi `intent`, `ClipData`, obsługa braku uprawnienia **Instalacja z nieznanych źródeł** (dialog + przejście do ustawień).
- **Pobieranie aktualizacji** — zapis na dysk przez strumień (mniej RAM); dialog z **`LinearProgressIndicator` i %-em**, gdy serwer podaje `Content-Length`.

### Drobne
- `dart analyze lib` bez problemów (`use_build_context_synchronously`, przestarzałe pole w wyborze płci).

---

## [v0.9.0-dev] — 2026-05-15

### Nowe funkcje
- **Nawigacja** — dolny pasek zakładek (`NavigationBar`) + menu boczne; `IndexedStack` utrzymuje stan ekranów.
- **Aktualności klubu** — lista wpisów, szczegóły artykułu, galeria zdjęć (API jak na witrynie).
- **Osiągnięcia** — odznaki zawodnika (Sinclair, dwubój, rwanie, podrzut, frekwencja) — logika jak `AthleteBadges` na WWW.
- **Dziennik regeneracji** — sen, zmęczenie, ból, gotowość.
- **Składki i starty** — status płatności, przypisanie do zawodów (poprawione API uczestników).
- **Frekwencja offline** — bufor obecności do synchronizacji po powrocie sieci.

### Ulepszenia
- Dashboard — skróty do nowych modułów, kafelek osiągnięć.
- Biometria — `FlutterFragmentActivity`, stabilniejszy `BiometricGate`.
- Profil — poprawki formularzy i motywu.

### Techniczne
- Wersja `pubspec`: `0.9.0+1`; Android `versionName` z tagu Git (`v0.9.0-dev`).
- Nowe modele i serwisy API (`club_post`, `gallery`, `recovery_log`, `attendance_summary`).

### Instalacja
Pobierz APK z [GitHub Releases](https://github.com/JakubGawron1/Slavia-Mobile/releases) (tag `v0.9.0-dev`) lub zsynchronizuj wydanie w panelu admina witryny.

---

## [v0.8.0] — 2026-05-11

Plany treningowe zawodnika i trenera, aktualizator APK z GitHub Releases, wersja z tagu Git.
