# FCM + go_router — fundament (Fala 2) i odroczenie pełnego zakresu

## Zrobione w Fali 2

| Element | Plik | Stan |
|---------|------|------|
| `go_router` | `lib/routing/app_router.dart`, `lib/main.dart` | Trasy: `/`, `/login`, `/banned`, `/browser-panel`, `/chat`, `/notifications` |
| FCM stub | `lib/services/fcm_service.dart` | Interfejs + log; `isAvailable == false` |
| Powiadomienia | `push_notification_service.dart` | Nadal polling 30s (bez regresji) |

## Odroczone (Fala 3+)

1. **Firebase** — `firebase_core`, `firebase_messaging`, `GoogleService-Info.plist`, `google-services.json`, rejestracja tokena w backendzie.
2. **Zastąpienie pollingu** — chat i powiadomienia klubowe przez push; polling jako fallback offline.
3. **Deep linki FCM** — `FcmService.handleNotificationTap` → `context.go(AppRoutes.chat)` itd.
4. **Quick Actions** — migracja z `Navigator.push` na `go_router` w `main_screen.dart`.
5. **Panel nav flags** — URL gate per moduł (`/athlete/plans` …) po stabilizacji tras.

## Kryteria zamknięcia MOB-A5 / PERF-5

- [ ] Token FCM zapisany w BE po logowaniu
- [ ] Push przy nowej wiadomości czatu (bez 30s opóźnienia)
- [ ] Test integracyjny: tap push → ekran czatu
- [ ] iOS APNs + Android 13+ permission flow udokumentowany w CI
