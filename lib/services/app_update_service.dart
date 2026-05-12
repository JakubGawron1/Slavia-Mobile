import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart'
    show OpenFilex, OpenResult, ResultType;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/mobile_github_release.dart';

class GithubLatestRelease {
  final String tagName;
  final String name;
  final String htmlUrl;
  final String? apkUrl;
  final String? body;

  GithubLatestRelease({
    required this.tagName,
    required this.name,
    required this.htmlUrl,
    this.apkUrl,
    this.body,
  });
}

/// Normalizuje tag / `versionName` do rdzenia semver (bez `v`, bez `+build`, bez sufiksu `-pre`).
String _semverCore(String s) {
  var t = s.trim();
  if (t.startsWith('v') || t.startsWith('V')) t = t.substring(1);
  t = t.split('+').first.trim();
  t = t.split('-').first.trim();
  return t;
}

/// Porównanie wersji z `tag_name` (np. `v1.2.10`) z `PackageInfo.version` (`1.2.3`).
bool isRemoteVersionNewer(String remoteTag, String currentVersion) {
  List<int> parts(String v) {
    final core = _semverCore(v);
    if (core.isEmpty) return <int>[0];
    return core
        .split('.')
        .map((seg) => int.tryParse(seg.trim()) ?? 0)
        .toList();
  }

  final a = parts(remoteTag);
  final b = parts(currentVersion);
  final len = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < len; i++) {
    final ai = i < a.length ? a[i] : 0;
    final bi = i < b.length ? b[i] : 0;
    if (ai > bi) return true;
    if (ai < bi) return false;
  }
  return false;
}

Future<GithubLatestRelease?> fetchLatestGithubRelease() async {
  final r = MobileGithubRelease.repo.trim();
  if (!MobileGithubRelease.isConfigured) return null;
  final uri = Uri.parse('https://api.github.com/repos/$r/releases/latest');
  final res = await http
      .get(
        uri,
        headers: const {
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          'User-Agent': 'Slavia-Mobile-UpdateCheck',
        },
      )
      .timeout(const Duration(seconds: 20));
  if (res.statusCode != 200) return null;
  final map = jsonDecode(res.body) as Map<String, dynamic>;
  final assets = (map['assets'] as List<dynamic>?) ?? [];
  String? apkUrl;
  for (final a in assets) {
    final m = a as Map<String, dynamic>;
    final name = (m['name'] as String? ?? '').toLowerCase();
    if (name.endsWith('.apk')) {
      apkUrl = m['browser_download_url'] as String?;
      break;
    }
  }
  return GithubLatestRelease(
    tagName: map['tag_name'] as String? ?? '',
    name: map['name'] as String? ?? '',
    htmlUrl: map['html_url'] as String? ?? '',
    apkUrl: apkUrl,
    body: map['body'] as String?,
  );
}

const _kDismissedTagKey = 'app_update_dismissed_tag';

class AppUpdateService {
  AppUpdateService._();
  static final AppUpdateService instance = AppUpdateService._();

  bool _checking = false;

  /// Automatyczne sprawdzenie przy starcie: [ignoreDismissed] = false.
  /// Z profilu: [ignoreDismissed] = true — pokaż też SnackBar, gdy nie wyświetlono dialogu.
  ///
  /// Zwraca tekst do SnackBara (np. „Masz aktualną wersję”), albo `null` gdy pokazano dialog lub pominięto cicho.
  Future<String?> checkAndOfferUpdate(
    BuildContext context, {
    bool ignoreDismissed = false,
  }) async {
    if (!MobileGithubRelease.isConfigured) {
      return ignoreDismissed
          ? 'Brak SLAVIA_MOBILE_GITHUB_REPO — nie skonfigurowano repozytorium wydań.'
          : null;
    }
    if (_checking) {
      return ignoreDismissed ? 'Sprawdzanie wersji już trwa…' : null;
    }
    _checking = true;
    try {
      final info = await PackageInfo.fromPlatform();
      GithubLatestRelease? rel;
      try {
        rel = await fetchLatestGithubRelease();
      } catch (_) {
        if (ignoreDismissed) {
          return 'Nie udało się połączyć z GitHub (sieć, timeout lub limit API). Spróbuj za chwilę.';
        }
        return null;
      }
      if (rel == null || rel.tagName.isEmpty) {
        if (ignoreDismissed) {
          return 'Brak danych o wydaniu (GitHub zwrócił błąd lub pustą odpowiedź).';
        }
        return null;
      }

      if (!isRemoteVersionNewer(rel.tagName, info.version)) {
        if (ignoreDismissed) {
          return 'Masz aktualną wersję: ${info.version} (build ${info.buildNumber}). '
              'Ostatnie wydanie na GitHubie: ${rel.tagName}.';
        }
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      if (!ignoreDismissed) {
        final dismissed = prefs.getString(_kDismissedTagKey);
        if (dismissed == rel.tagName) return null;
      }

      if (!context.mounted) return null;
      final GithubLatestRelease release = rel;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Nowa wersja aplikacji Slavia'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ta sama aplikacja co na stronie klubu — zalecamy aktualizację z najnowszego wydania.',
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Zainstalowana: ${info.version} (build ${info.buildNumber})',
                ),
                const SizedBox(height: 8),
                Text('Wydanie na GitHubie: ${release.tagName}'),
                if (release.name.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    release.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
                if (release.body != null && release.body!.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    release.body!.trim(),
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
                if (Platform.isIOS) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Na iPhone/iPad zwykle aktualizacja trafia przez TestFlight lub dystrybucję przygotowaną przez klub — ten sam kanał co strona www.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await prefs.setString(_kDismissedTagKey, release.tagName);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Później'),
            ),
            TextButton(
              onPressed: () async {
                final u = Uri.tryParse(release.htmlUrl);
                if (u != null) {
                  await launchUrl(u, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Strona wydania'),
            ),
            if (Platform.isAndroid && release.apkUrl != null)
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _downloadAndInstallApk(
                    context,
                    release.apkUrl!,
                    release.tagName,
                  );
                },
                child: const Text('Pobierz i zainstaluj'),
              ),
          ],
        ),
      );
      return null;
    } catch (_) {
      if (ignoreDismissed) {
        return 'Wystąpił nieoczekiwany błąd podczas sprawdzania aktualizacji.';
      }
      return null;
    } finally {
      _checking = false;
    }
  }

  Future<void> _downloadAndInstallApk(
    BuildContext context,
    String apkUrl,
    String tagForPrefs,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pobieranie aktualizacji…'),
        duration: Duration(seconds: 45),
      ),
    );
    try {
      final res = await http
          .get(Uri.parse(apkUrl))
          .timeout(const Duration(minutes: 5));
      if (res.statusCode != 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Błąd pobierania: ${res.statusCode}')),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/slavia_update_${DateTime.now().millisecondsSinceEpoch}.apk';
      final f = File(path);
      await f.writeAsBytes(res.bodyBytes, flush: true);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (Platform.isAndroid) {
        const ch = MethodChannel('slavia_mobile/install_apk');
        try {
          await ch.invokeMethod<bool>('install', <String, dynamic>{
            'path': path,
          });
        } on PlatformException catch (e) {
          final OpenResult result = await OpenFilex.open(
            path,
            type: 'application/vnd.android.package-archive',
          );
          if (result.type != ResultType.done && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Instalacja: ${e.message ?? e.code}; open_filex: ${result.message}',
                ),
              ),
            );
          }
        }
      } else {
        final OpenResult result = await OpenFilex.open(path);
        if (result.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Otwieranie instalatora: ${result.message}'),
            ),
          );
        }
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDismissedTagKey, tagForPrefs);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Błąd: $e')));
      }
    }
  }
}
