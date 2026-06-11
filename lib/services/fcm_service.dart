import 'dart:developer' as developer;

import 'api_service.dart';

/// Foundation for Firebase Cloud Messaging — full rollout deferred (Fala 3+).
///
/// Today notifications use [PushNotificationService] (30s polling + local OS alerts).
/// Next steps: add `firebase_core` + `firebase_messaging`, `google-services.json`,
/// backend endpoint for device tokens, then replace polling for chat/club events.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  bool _initialized = false;
  ApiService? _api;

  /// `false` until Firebase project + native config are wired.
  bool get isAvailable => false;

  Future<void> init(ApiService apiService) async {
    if (_initialized) return;
    _initialized = true;
    _api = apiService;
    developer.log(
      'FCM foundation ready — polling remains active until Firebase is configured',
      name: 'FcmService',
    );
  }

  /// Reserved for `FirebaseMessaging.instance.getToken()` + POST to backend.
  Future<String?> registerDeviceToken() async {
    if (!isAvailable || _api == null) return null;
    return null;
  }

  /// Reserved for `onMessage` / `onMessageOpenedApp` → `GoRouter.go(AppRoutes.chat)`.
  void handleNotificationTap(Map<String, String> data) {
    developer.log('FCM tap (stub): $data', name: 'FcmService');
  }
}
