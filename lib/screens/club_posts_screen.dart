import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/club_post.dart';
import '../services/api_service.dart';
import '../ui/slavia_ui.dart';
import '../utils/html_plain_text.dart';
import 'club_post_detail_screen.dart';

/// Lista aktualności z `/api/posts` — odpowiednik `/aktualnosci` na WWW.
class ClubPostsScreen extends StatefulWidget {
  const ClubPostsScreen({super.key});

  @override
  State<ClubPostsScreen> createState() => _ClubPostsScreenState();
}

class _ClubPostsScreenState extends State<ClubPostsScreen> {
  Future<List<ClubPost>>? _future;

  Future<void> _reload() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final f = api.getClubPosts();
    setState(() => _future = f);
    await f;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _reload();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Aktualności klubu', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Odśwież',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<ClubPost>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }
            if (snap.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Icon(Icons.cloud_off_rounded, size: 48, color: cs.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Nie udało się wczytać aktualności.',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snap.error}',
                    style: GoogleFonts.outfit(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.65)),
                  ),
                ],
              );
            }
            final list = snap.data ?? [];
            if (list.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 48),
                  Icon(Icons.article_outlined, size: 56, color: cs.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Brak opublikowanych wpisów',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gdy klub doda news na stronie, pojawi się tutaj.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: cs.onSurface.withValues(alpha: 0.6),
                      height: 1.35,
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final p = list[i];
                final excerpt = htmlToPlainText(p.content);
                final short = excerpt.length > 140 ? '${excerpt.substring(0, 140)}…' : excerpt;
                final dateStr = DateFormat.yMMMMd('pl_PL').format(p.createdAt.toLocal());
                return Material(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ClubPostDetailScreen(post: p),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
                        border: Border.all(color: primary.withValues(alpha: 0.12)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.title,
                            style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, height: 1.25),
                          ),
                          if (short.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              short,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                height: 1.4,
                                color: cs.onSurface.withValues(alpha: 0.78),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
