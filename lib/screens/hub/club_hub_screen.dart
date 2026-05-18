import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_brand.dart';
import '../../models/announcement.dart';
import '../../services/api_service.dart';
import '../../ui/slavia_ui.dart';
import '../announcement_page.dart';
import '../club_gallery_screen.dart';
import '../club_posts_screen.dart';

/// Zakładka „Klub” — ogłoszenia, aktualności, galeria.
class ClubHubScreen extends StatelessWidget {
  const ClubHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final api = Provider.of<ApiService>(context, listen: false);

    void push(Widget page) {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => page),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SlaviaUi.homeBadge(context, 'KLUB'),
                  const SizedBox(height: 10),
                  Text(
                    'Klub',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ogłoszenia, aktualności i galeria — to samo co na stronie klubu.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      height: 1.4,
                      color: cs.onSurface.withValues(alpha: 0.58),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: SlaviaUi.sectionHeader(
                      context,
                      'Ogłoszenia',
                      accent: primary,
                      icon: Icons.campaign_outlined,
                    ),
                  ),
                  TextButton(
                    onPressed: () => push(const AnnouncementPage()),
                    child: Text(
                      'Wszystkie',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: FutureBuilder<List<Announcement>>(
              future: api.getAnnouncements(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  );
                }
                final list = snap.data?.take(4).toList() ?? [];
                if (list.isEmpty) {
                  return SliverToBoxAdapter(
                    child: SlaviaUi.emptyState(
                      context,
                      icon: Icons.campaign_outlined,
                      title: 'Brak ogłoszeń',
                      subtitle: 'Nowe ogłoszenia pojawią się tutaj.',
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final a = list[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
                          child: InkWell(
                            onTap: () => push(const AnnouncementPage()),
                            borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
                            child: Ink(
                              decoration: SlaviaUi.cardShell(context, borderTint: primary),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      DateFormat('d MMM yyyy', 'pl_PL').format(a.createdAt),
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: cs.onSurface.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      a.title,
                                      style: GoogleFonts.outfit(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (a.body.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        a.body,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          height: 1.35,
                                          color: cs.onSurface.withValues(alpha: 0.72),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: list.length,
                  ),
                );
              },
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SlaviaUi.sectionHeader(
                  context,
                  'Więcej z klubu',
                  accent: cs.tertiary,
                  icon: Icons.groups_rounded,
                ),
                SlaviaUi.hubTile(
                  context,
                  title: 'Aktualności',
                  subtitle: 'Wpisy redakcyjne klubu',
                  icon: Icons.article_outlined,
                  accent: Colors.teal,
                  onTap: () => push(const ClubPostsScreen()),
                ),
                const SizedBox(height: 10),
                SlaviaUi.hubTile(
                  context,
                  title: 'Galeria',
                  subtitle: 'Zdjęcia i filmy z treningów',
                  icon: Icons.photo_library_outlined,
                  accent: Colors.indigo,
                  onTap: () => push(const ClubGalleryScreen()),
                ),
                if (AppBrand.hasPublicSite) ...[
                  const SizedBox(height: 10),
                  SlaviaUi.hubTile(
                    context,
                    title: 'Strona klubu',
                    subtitle: AppBrand.publicSiteLabel,
                    icon: Icons.public_rounded,
                    accent: primary,
                    onTap: () async {
                      final messenger = ScaffoldMessenger.maybeOf(context);
                      final ok = await AppBrand.openPublicSite();
                      if (!ok && messenger != null && messenger.mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              'Nie udało się otworzyć strony.',
                              style: GoogleFonts.outfit(),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
