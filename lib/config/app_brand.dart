import 'package:url_launcher/url_launcher.dart';

/// Publiczny frontend Nuxt. Domyślnie produkcja: https://cksslavia.vercel.app/
/// Nadpisanie: `flutter run --dart-define=SLAVIA_WEB_URL=https://inna-domena.pl`
abstract final class AppBrand {
  AppBrand._();

  static const String _raw = String.fromEnvironment(
    'SLAVIA_WEB_URL',
    defaultValue: 'https://cksslavia.vercel.app',
  );

  static Uri? get publicSiteUri {
    final t = _raw.trim();
    if (t.isEmpty) return null;
    final normalized = t.contains('://') ? t : 'https://$t';
    return Uri.tryParse(normalized);
  }

  static bool get hasPublicSite => publicSiteUri != null;

  static String get publicSiteLabel {
    final u = publicSiteUri;
    if (u == null) return '';
    return u.host;
  }

  static Future<bool> openPublicSite() async {
    final u = publicSiteUri;
    if (u == null) return false;
    return launchUrl(u, mode: LaunchMode.externalApplication);
  }
}
