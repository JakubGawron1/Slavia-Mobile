import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/mobile_github_release.dart';
import 'last_error_recorder.dart';

/// Idea #139 + szablon #209 — otwiera zgłoszenie GitHub z wklejką diagnostyczną w schowku.
Future<void> openMobileBugReporter(BuildContext context) async {
  if (!MobileGithubRelease.isConfigured) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Brak SLAVIA_MOBILE_GITHUB_REPO — ustaw przy buildzie, by zgłaszać przez GitHub.',
          style: GoogleFonts.outfit(),
        ),
      ),
    );
    return;
  }

  final info = await PackageInfo.fromPlatform();
  final buffer = StringBuffer()
    ..writeln('--- automatycznie zebrane (bez danych medycznych) ---')
    ..writeln('Wersja: ${info.version} (build ${info.buildNumber})')
    ..writeln('Urządzenie: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');

  final last = LastErrorRecorder.friendlyPreview;
  if (last != null && last.isNotEmpty) {
    buffer.writeln('Ostatni błąd (skrót): $last');
  } else {
    buffer.writeln('Ostatni błąd: brak zapisanego komunikatu w tej sesji.');
  }

  final clip = buffer.toString();
  await Clipboard.setData(ClipboardData(text: clip));

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Skopiowano diagnostykę do schowka — wklej ją w polu szablonu na GitHubie.',
        style: GoogleFonts.outfit(),
      ),
    ),
  );

  final uri = Uri.https(
    'github.com',
    '/${MobileGithubRelease.repo}/issues/new',
    <String, String>{
      'template': 'mobile_bug.yml',
      'labels': 'mobile,bug',
      'title': '[Mobile] ',
    },
  );

  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!context.mounted) return;
  if (!ok) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Nie udało się otworzyć przeglądarki: $uri',
          style: GoogleFonts.outfit(),
        ),
      ),
    );
  }
}
