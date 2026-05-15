import '../config/app_brand.dart';

/// Uzupełnia względne ścieżki mediów (np. z uploadu) adresem frontu klubu.
String resolveClubMediaUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  final u = url.trim();
  if (u.startsWith('http://') || u.startsWith('https://')) return u;
  if (u.startsWith('//')) return 'https:$u';
  final web = AppBrand.publicSiteUri;
  if (u.startsWith('/') && web != null) {
    return web.resolve(u).toString();
  }
  return u;
}
