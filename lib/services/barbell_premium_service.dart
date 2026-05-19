import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth.dart';

/// Premium offline — analiza toru sztangi w aplikacji bez sieci.
/// Kadra klubu ma dostęp domyślnie; zawodnicy mogą odblokować lokalnie (beta / IAP w przyszłości).
class BarbellPremiumService extends ChangeNotifier {
  static const _athleteUnlockKey = 'slavia_barbell_premium_athlete_unlock_v1';

  bool _athleteUnlock = false;
  bool _loaded = false;

  bool get athleteUnlock => _athleteUnlock;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _athleteUnlock = prefs.getBool(_athleteUnlockKey) ?? false;
    _loaded = true;
  }

  bool isPremiumFor(AuthUser? user) {
    if (user == null) return false;
    final roles = user.roles;
    if (roles.contains('SuperAdmin') ||
        roles.contains('Admin') ||
        roles.contains('Trainer')) {
      return true;
    }
    if (roles.contains('Athlete') && _athleteUnlock) {
      return true;
    }
    return false;
  }

  Future<void> unlockAthleteBeta() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_athleteUnlockKey, true);
    _athleteUnlock = true;
    notifyListeners();
  }

  Future<void> revokeAthleteUnlock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_athleteUnlockKey);
    _athleteUnlock = false;
    notifyListeners();
  }
}
