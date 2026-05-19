# Podpisywanie APK Android — CKS Slavia Mobile

## Dlaczego GitHub APK ma inny podpis niż lokalna instalacja?

Android traktuje każdy APK jako **aktualizację tej samej aplikacji** tylko wtedy, gdy **podpis cyfrowy (keystore) jest identyczny**. Gdy podpisy się różnią, system pokazuje błąd typu „Aplikacja nie została zainstalowana” albo wymusza odinstalowanie poprzedniej wersji.

Typowe przyczyny w Slavia Mobile:

| Źródło APK | Keystore | Efekt |
|------------|----------|--------|
| `flutter build apk --release` lokalnie (domyślnie) | Debug keystore **na Twoim PC** (`~/.android/debug.keystore`) | Podpis A |
| GitHub Actions (`Release APK`) bez sekretów | Debug keystore **na runnerze CI** | Podpis B ≠ A |
| GitHub Release po skonfigurowaniu sekretów | Ten sam release keystore | Spójny podpis |

**Wniosek:** lokalny release i CI muszą używać **tego samego pliku `.jks` / `.keystore`**, albo na urządzeniu trzeba odinstalować starą wersję przed instalacją APK z innego źródła.

## Zalecany workflow

1. Wygeneruj **jeden** keystore release (raz, bezpiecznie zrób kopię zapasową):

   ```bash
   keytool -genkey -v -keystore slavia-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias slavia
   ```

2. Ustaw zmienne środowiskowe (lokalnie i w GitHub Secrets):

   | Zmienna | Opis |
   |---------|------|
   | `ANDROID_KEYSTORE_PATH` | Ścieżka do pliku `.jks` |
   | `ANDROID_KEYSTORE_PASSWORD` | Hasło keystore |
   | `ANDROID_KEY_ALIAS` | Alias klucza (np. `slavia`) |
   | `ANDROID_KEY_PASSWORD` | Hasło klucza |

3. W GitHub → **Settings → Secrets and variables → Actions** dodaj powyższe sekrety oraz wgraj keystore jako artifact w bezpiecznym miejscu (np. zaszyfrowany w repo prywatnym lub menedżer haseł zespołu).

4. `android/app/build.gradle.kts` automatycznie używa release keystore, gdy `ANDROID_KEYSTORE_PATH` jest ustawione; w przeciwnym razie fallback na debug (wygodne do dev, **nie** do dystrybucji).

## versionCode i aktualizacje w aplikacji

- **`versionName`** — z tagu Git (`v0.9.10-dev`) lub najnowszego tagu `v*`.
- **`versionCode`** — `git rev-list --count HEAD * 1000 + buildNumber z pubspec.yaml`.

Przed buildem release:

```bash
git fetch --tags
git pull
```

Dzięki temu lokalny APK i GitHub Release mają **ten sam numer wersji** i monotonicznie rosnący `versionCode` — wymagane przez instalator w aplikacji (`AppUpdateService`).

## Instalacja gdy podpisy się różnią

1. Odinstaluj starą wersję CKS Slavia z telefonu.
2. Zainstaluj APK z jednego, stałego źródła (np. tylko GitHub Releases po skonfigurowaniu keystore).

Po ujednoliceniu keystore kolejne aktualizacje instalują się bez odinstalowywania.
