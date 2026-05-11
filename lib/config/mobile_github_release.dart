/// Repozytorium GitHub z APK. Domyślnie `JakubGawron1/Slavia-Mobile`.
/// Nadpisz przy buildzie: `--dart-define=SLAVIA_MOBILE_GITHUB_REPO=inny/wlasny-repo`.
abstract final class MobileGithubRelease {
  MobileGithubRelease._();

  static const String repo = String.fromEnvironment(
    'SLAVIA_MOBILE_GITHUB_REPO',
    defaultValue: 'JakubGawron1/Slavia-Mobile',
  );

  static bool get isConfigured =>
      repo.trim().isNotEmpty &&
      RegExp(r'^[\w.-]+/[\w.-]+$').hasMatch(repo.trim());
}
