import 'dart:async';
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
/// Porównanie numeru build (versionCode) z tagu GitHub (`v1.2.3+45`) lub samego buildu.
bool isRemoteBuildNewer(String remoteTag, String currentBuildNumber) {
  int? buildFromTag(String tag) {
    final t = tag.trim();
    final plus = t.lastIndexOf('+');
    if (plus >= 0 && plus < t.length - 1) {
      return int.tryParse(t.substring(plus + 1).trim());
    }
    return null;
  }

  final remoteBuild = buildFromTag(remoteTag);
  final localBuild = int.tryParse(currentBuildNumber.trim());
  if (remoteBuild != null && localBuild != null) {
    return remoteBuild > localBuild;
  }
  return false;
}

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
const _installChannel = MethodChannel('slavia_mobile/install_apk');

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

      final semverNewer = isRemoteVersionNewer(rel.tagName, info.version);
      final buildNewer = isRemoteBuildNewer(rel.tagName, info.buildNumber);
      if (!semverNewer && !buildNewer) {
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

  Future<bool> _ensureAndroidInstallAllowed(BuildContext context) async {
    if (!Platform.isAndroid) return true;
    final dynamic raw = await _installChannel.invokeMethod(
      'canRequestPackageInstalls',
    );
    final can = raw == true;
    if (can) return true;
    if (!context.mounted) return false;
    final open = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => AlertDialog(
        title: const Text('Zezwolenie na instalację'),
        content: const Text(
          'Android blokuje instalowanie aktualizacji z aplikacji, dopóki nie zezwolisz '
          '„CKS Slavia” na instalowanie aplikacji z nieznanych źródeł.\n\n'
          'Po otwarciu ustawień włącz przełącznik i wróć — ponów „Pobierz i zainstaluj”.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dlgCtx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: const Text('Ustawienia'),
          ),
        ],
      ),
    );
    if (open != true || !context.mounted) return false;
    try {
      await _installChannel.invokeMethod<void>('openManageUnknownAppSources');
    } catch (_) {}
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Włącz instalację dla CKS Slavia w ustawieniach Androida, potem ponów pobieranie.',
        ),
        duration: Duration(seconds: 6),
      ),
    );
    return false;
  }

  Future<void> _downloadAndInstallApk(
    BuildContext context,
    String apkUrl,
    String tagForPrefs,
  ) async {
    if (Platform.isAndroid) {
      final allowed = await _ensureAndroidInstallAllowed(context);
      if (!allowed || !context.mounted) return;
      final dynamic again =
          await _installChannel.invokeMethod('canRequestPackageInstalls');
      if (again != true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Android nie zezwolił jeszcze na instalację z tej aplikacji — sprawdź ustawienia.',
              ),
            ),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;

    final progress = ValueNotifier<double>(0);
    final indeterminate = ValueNotifier<bool>(true);

    void closeProgressUi() {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).maybePop();
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => PopScope(
        canPop: false,
        child: AnimatedBuilder(
          animation: Listenable.merge([progress, indeterminate]),
          builder: (context, _) {
            final useInd = indeterminate.value;
            final value = progress.value.clamp(0.0, 1.0);
            final pct = (value * 100).floor();
            return AlertDialog(
                  title: const Text('Pobieranie aktualizacji'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (useInd)
                        const LinearProgressIndicator()
                      else
                        LinearProgressIndicator(value: value),
                      const SizedBox(height: 12),
                      Text(
                        useInd
                            ? 'Pobieranie… (brak rozmiaru z serwera — bez %)'
                            : '$pct%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Po zakończeniu otworzy się instalator systemu.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
          },
        ),
      ),
    );

    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(apkUrl));
      final streamed = await client
          .send(req)
          .timeout(const Duration(minutes: 10));

      if (streamed.statusCode != 200) {
        closeProgressUi();
        progress.dispose();
        indeterminate.dispose();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd pobierania: HTTP ${streamed.statusCode}'),
          ),
        );
        return;
      }

      final totalBytes = streamed.contentLength;
      final hasTotal = totalBytes != null && totalBytes > 0;
      indeterminate.value = !hasTotal;

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/slavia_update_${DateTime.now().millisecondsSinceEpoch}.apk';
      final file = File(path);
      final sink = file.openWrite();

      var received = 0;
      await for (final chunk
          in streamed.stream.timeout(const Duration(minutes: 15))) {
        sink.add(chunk);
        received += chunk.length;
        if (hasTotal) {
          progress.value = (received / totalBytes).clamp(0.0, 1.0);
        }
      }
      await sink.close();
      indeterminate.value = false;
      progress.value = 1;

      closeProgressUi();
      progress.dispose();
      indeterminate.dispose();

      if (!context.mounted) return;

      if (Platform.isAndroid) {
        try {
          await _installChannel.invokeMethod<bool>('install', <String, dynamic>{
            'path': path,
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Otwarto instalator systemu. Dokończ instalację na ekranie Androida. '
                  'Komunikat „aplikacja nie została zainstalowana” zwykle oznacza anulowanie, '
                  'ten sam numer build co obecna wersja lub inny podpis APK (debug vs release).',
                ),
                duration: Duration(seconds: 8),
              ),
            );
          }
        } on PlatformException catch (e) {
          final OpenResult openResult = await OpenFilex.open(
            path,
            type: 'application/vnd.android.package-archive',
          );
          if (openResult.type != ResultType.done && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${e.message ?? e.code}; otwarcie pliku: ${openResult.message}',
                ),
              ),
            );
          }
        }
      } else {
        final OpenResult openResult = await OpenFilex.open(path);
        if (openResult.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Otwieranie pliku: ${openResult.message}'),
            ),
          );
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDismissedTagKey, tagForPrefs);
    } on TimeoutException catch (_) {
      closeProgressUi();
      progress.dispose();
      indeterminate.dispose();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Przekroczono czas pobierania. Sprawdź sieć i spróbuj ponownie.',
            ),
          ),
        );
      }
    } catch (e) {
      closeProgressUi();
      progress.dispose();
      indeterminate.dispose();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd: $e')),
        );
      }
    } finally {
      client.close();
    }
  }
}
