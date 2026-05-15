# Changelog — Slavia Mobile

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
