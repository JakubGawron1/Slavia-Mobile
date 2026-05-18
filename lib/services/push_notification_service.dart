import 'dart:async';
import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Polls the backend every 30 seconds. If a new unread notification arrives
/// (ID not seen before), it fires a system OS notification.
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._();
  factory PushNotificationService() => _instance;
  PushNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Timer? _timer;
  bool _initialized = false;
  ApiService? _apiService;

  /// Udostępnione np. do zaplanowanych przypomnień o startach (#148).
  FlutterLocalNotificationsPlugin get plugin => _plugin;

  static const _channelClubId = 'slavia_club';
  static const _channelClubName = 'Slavia: klub';
  static const _channelChatId = 'slavia_chat';
  static const _channelChatName = 'Slavia: czat';
  static const _prefKey = 'seen_notification_ids';

  String _channelForKind(String kind) {
    final k = kind.toLowerCase();
    if (k.contains('chat')) return _channelChatId;
    return _channelClubId;
  }

  String _channelNameForId(String id) {
    if (id == _channelChatId) return _channelChatName;
    return _channelClubName;
  }

  Future<void> init(ApiService apiService) async {
    _apiService = apiService;
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // v20 uses named parameter `settings:`
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Request runtime permission on Android 13+
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
  }

  void startPolling() {
    _timer?.cancel();
    _checkForNew();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _checkForNew());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkForNew() async {
    if (_apiService == null) return;
    try {
      final notifications = await _apiService!.getNotifications();
      final prefs = await SharedPreferences.getInstance();
      final seen = Set<String>.from(prefs.getStringList(_prefKey) ?? []);

      final newOnes = notifications
          .where((n) => !n.isRead && !seen.contains(n.id))
          .toList();

      for (final n in newOnes) {
        await _showSystemNotification(
          n.id.hashCode,
          n.title,
          n.body,
          kind: n.kind,
        );
        seen.add(n.id);
      }

      await prefs.setStringList(_prefKey, seen.toList());

      final unread = notifications.where((n) => !n.isRead).length;
      await AppBadgePlus.updateBadge(unread);
    } catch (_) {
      // Silently fail — network might be unavailable
    }
  }

  Future<void> _showSystemNotification(
    int id,
    String title,
    String body, {
    String kind = 'info',
  }) async {
    final channelId = _channelForKind(kind);
    final channelName = _channelNameForId(channelId);
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelId == _channelChatId
          ? 'Wiadomości z czatu trener–zawodnik'
          : 'Powiadomienia klubowe CKS Slavia',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/launcher_icon',
      groupKey: channelId,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'slavia_notifications',
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
    );
  }

  /// Clear seen IDs on logout so we don't miss notifications on next login
  Future<void> clearSeenIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  /// Po usunięciu powiadomienia usuń ID z cache — inaczej lista „seen” rośnie bez końca.
  Future<void> forgetNotificationIds(Iterable<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = Set<String>.from(prefs.getStringList(_prefKey) ?? []);
    for (final id in ids) {
      seen.remove(id);
    }
    await prefs.setStringList(_prefKey, seen.toList());
  }

  /// Aktualizacja znaczka ikony (idea #132) — np. po przeczytaniu listy.
  Future<void> refreshBadgeFromApi() async {
    if (_apiService == null) return;
    try {
      final notifications = await _apiService!.getNotifications();
      final unread = notifications.where((n) => !n.isRead).length;
      await AppBadgePlus.updateBadge(unread);
    } catch (_) {}
  }
}
