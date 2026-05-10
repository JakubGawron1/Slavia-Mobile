import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../models/announcement.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final apiService = Provider.of<ApiService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _buildHero(context, auth.user?.username ?? 'Zawodnik',
                  auth.user?.avatarUrl ?? auth.user?.athleteImageUrl, isDark, primary),
            ),
          ),

          // Quick stats row
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  _QuickStatCard(
                    icon: Icons.bolt,
                    label: 'Aktywny',
                    value: auth.user?.roles?.first ?? 'Zawodnik',
                    primary: primary,
                  ),
                  const SizedBox(width: 12),
                  _QuickStatCard(
                    icon: Icons.calendar_today,
                    label: 'Dziś',
                    value: DateFormat('d MMM', 'pl_PL').format(DateTime.now()),
                    primary: primary,
                  ),
                ],
              ),
            ),
          ),

          // Announcements title
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ogłoszenia',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Wszystkie', style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: primary)),
                  ),
                ],
              ),
            ),
          ),

          // Announcements list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<List<Announcement>>(
                future: apiService.getAnnouncements(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Column(
                      children: List.generate(3, (i) => _AnnouncementSkeleton(isDark: isDark)),
                    );
                  }
                  final list = snapshot.data?.take(5).toList() ?? [];
                  if (list.isEmpty) {
                    return _EmptyState(
                      icon: Icons.campaign_outlined,
                      title: 'Brak ogłoszeń',
                      subtitle: 'Nowe ogłoszenia pojawią się tutaj.',
                    );
                  }
                  return Column(
                    children: list.asMap().entries.map((e) =>
                      _AnnouncementCard(announcement: e.value, index: e.key, primary: primary, isDark: isDark),
                    ).toList(),
                  );
                },
              ),
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, String name, String? imageUrl, bool isDark, Color primary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            primary.withOpacity(0.75),
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background dots
          Positioned(
            right: -10,
            top: -20,
            child: Opacity(
              opacity: 0.15,
              child: Icon(Icons.sports_gymnastics, size: 100, color: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cześć, $name 👋',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'CKS Slavia Ruda Śląska',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (imageUrl != null) ...[
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12),
                        ],
                      ),
                      child: CircleAvatar(radius: 32, backgroundImage: NetworkImage(imageUrl)),
                    ),
                  ] else ...[
                    const SizedBox(width: 16),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 3),
                      ),
                      child: Center(
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color primary;

  const _QuickStatCard({required this.icon, required this.label, required this.value, required this.primary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.outfit(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                  Text(value, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final int index;
  final Color primary;
  final bool isDark;

  const _AnnouncementCard({required this.announcement, required this.index, required this.primary, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, val, child) => Transform.translate(
        offset: Offset(0, 16 * (1 - val)),
        child: Opacity(opacity: val, child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primary.withOpacity(0.08)),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.campaign, color: primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.title,
                          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          announcement.body,
                          style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementSkeleton extends StatelessWidget {
  final bool isDark;
  const _AnnouncementSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(14))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: 180, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 8),
                Container(height: 12, width: 120, decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(8))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }
}
