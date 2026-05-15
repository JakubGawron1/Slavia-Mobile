# Polityka wspieranych wersji SDK (CKS Slavia Mobile)

## Android
- **minSdk**: zgodnie z `android/app/build.gradle.kts` / Flutter (obecnie API 21+).
- **targetSdk**: najnowszy wymagany przez Google Play w momencie publikacji.
- **Biometria**: wymaga `FlutterFragmentActivity` w `MainActivity`.
- **Split-screen**: `resizeableActivity` włączone; testować obrót i zmianę szerokości okna.

## iOS
- **Minimum**: iOS 12+ (Flutter default); Face ID wymaga `NSFaceIDUsageDescription` w `Info.plist`.
- **Widgety / Live Activities**: nie są częścią minimalnego wsparcia — osobny release gdy dodane.

## Funkcje a wersja systemu
| Funkcja | Android | iOS |
|---------|---------|-----|
| Push (FCM/APNs) | 8+ | 10+ |
| Skróty ekranu głównego | 7.1+ | 13+ (Quick Actions) |
| Biometria | 6+ (odcisk) | Touch/Face ID |

Aktualizuj ten dokument przy podbijaniu `minSdk` / wymagań sklepu.
