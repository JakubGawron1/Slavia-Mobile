import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/club_post.dart';
import '../ui/slavia_ui.dart';
import '../utils/html_plain_text.dart';
import '../utils/resolve_media_url.dart';

/// Szczegóły wpisu — treść HTML z serwisu pokazujemy jako czytelny tekst.
class ClubPostDetailScreen extends StatelessWidget {
  const ClubPostDetailScreen({super.key, required this.post});

  final ClubPost post;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;
    final img = resolveClubMediaUrl(post.imageUrl);
    final body = htmlToPlainText(post.content);
    final dateStr = DateFormat.yMMMMd('pl_PL').add_Hm().format(post.createdAt.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: Text('Aktualność', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              dateStr,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              post.title,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, height: 1.2),
            ),
            if (img.isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.network(
                    img,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: cs.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image_outlined, color: cs.outline, size: 40),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SelectableText(
              body.isEmpty ? '—' : body,
              style: GoogleFonts.outfit(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(SlaviaUi.radiusMd),
                border: Border.all(color: primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Formatowanie z WWW (pogrubienia, listy) jest tu uproszczone do tekstu.',
                      style: GoogleFonts.outfit(fontSize: 12, height: 1.35, color: cs.onSurface.withValues(alpha: 0.75)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
