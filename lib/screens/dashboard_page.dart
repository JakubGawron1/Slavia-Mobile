import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/api_service.dart';
import '../models/announcement.dart';
import '../models/athlete.dart';
import '../utils/training_streak.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'announcement_page.dart';
import 'athlete_portal_screen.dart';
import 'competition_assignment_screen.dart';
import 'proportions_calculator_page.dart';
import 'sinclair_calculator_page.dart';
import '../ui/slavia_ui.dart';
import 'athlete_training_plans_screen.dart';
import 'trainer_training_plans_screen.dart';
import 'training_log_screen.dart';
import 'recovery_journal_screen.dart';
import 'athlete_timeline_screen.dart';
import 'athlete_achievements_screen.dart';
import '../models/club_post.dart';
import '../utils/html_plain_text.dart';
import 'club_posts_screen.dart';
import 'club_post_detail_screen.dart';
import 'club_gallery_screen.dart';
import 'barbell_analysis_screen.dart';

String _primaryRoleLabel(List<String> roles) {
  if (roles.contains('SuperAdmin')) return 'SuperAdmin';
  if (roles.contains('Admin')) return 'Administrator';
  if (roles.contains('Trainer')) return 'Trener';
  if (roles.contains('Athlete')) return 'Zawodnik';
  if (roles.isEmpty) return 'Konto';
  return roles.first;
}

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
              child: _buildHero(
                context,
                auth.user?.username ?? 'Zawodnik',
                auth.user?.avatarUrl ?? auth.user?.athleteImageUrl,
                isDark,
                primary,
              ),
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
                    value: _primaryRoleLabel(auth.user?.roles ?? []),
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

          if (auth.user?.roles.contains('Athlete') == true &&
              (auth.user?.athleteId ?? '').isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: FutureBuilder<List<TrainingLogEntry>>(
                  future: apiService.getTrainingLog(auth.user!.athleteId!),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting &&
                        !snap.hasData) {
                      return const SizedBox.shrink();
                    }
                    if (snap.hasError || !snap.hasData) {
                      return const SizedBox.shrink();
                    }
                    final streak = computeTrainingLogStreak(snap.data!);
                    return _TrainingStreakBanner(
                      streak: streak,
                      primary: primary,
                    );
                  },
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _QuickAccessRow(auth: auth, primary: primary),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _ClubPostsPreview(apiService: apiService, primary: primary),
            ),
          ),

          // Announcements title
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Ogłoszenia',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (ctx) => Scaffold(
                              appBar: AppBar(
                                title: Text(
                                  'Ogłoszenia',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              body: const AnnouncementPage(),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Wszystkie',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primary,
                          ),
                        ),
                      ),
                    ),
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
                      children: List.generate(
                        3,
                        (i) => _AnnouncementSkeleton(isDark: isDark),
                      ),
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
                    children: list
                        .asMap()
                        .entries
                        .map(
                          (e) => _AnnouncementCard(
                            announcement: e.value,
                            index: e.key,
                            primary: primary,
                            isDark: isDark,
                          ),
                        )
                        .toList(),
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

  Widget _buildHero(
    BuildContext context,
    String name,
    String? imageUrl,
    bool isDark,
    Color primary,
  ) {
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
            primary.withValues(alpha: 0.75),
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.35),
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
              child: Icon(
                Icons.sports_gymnastics,
                size: 100,
                color: Colors.white,
              ),
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
                            color: Colors.white.withValues(alpha: 0.75),
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
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: NetworkImage(imageUrl),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(width: 16),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 26,
                          ),
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

class _TrainingStreakBanner extends StatelessWidget {
  final int streak;
  final Color primary;

  const _TrainingStreakBanner({
    required this.streak,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = streak <= 0
        ? 'Zapisuj treningi w dzienniku — zbuduj serię kolejnych dni.'
        : streak == 1
            ? 'Seria treningów: 1 dzień z rzędu.'
            : 'Seria treningów: $streak dni z rzędu — tak trzymaj.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.18),
            cs.secondary.withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: primary.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_rounded, color: primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessRow extends StatelessWidget {
  final AuthProvider auth;
  final Color primary;

  const _QuickAccessRow({required this.auth, required this.primary});

  @override
  Widget build(BuildContext context) {
    final roles = auth.user?.roles ?? <String>[];
    final isAthlete = roles.contains('Athlete');
    final isStaff = roles.any(
      (r) => r == 'Trainer' || r == 'Admin' || r == 'SuperAdmin',
    );

    void push(Widget page) {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => page),
      );
    }

    final tiles = <Widget>[
      _quickTile(
        context,
        'Aktualności',
        Icons.newspaper_rounded,
        Colors.teal,
        () => push(const ClubPostsScreen()),
      ),
      _quickTile(
        context,
        'Galeria',
        Icons.photo_library_outlined,
        Colors.indigo,
        () => push(const ClubGalleryScreen()),
      ),
      _quickTile(
        context,
        'Sinclair',
        Icons.calculate_rounded,
        Colors.amber,
        () => push(const SinclairCalculatorPage()),
      ),
      _quickTile(
        context,
        'Proporcje',
        Icons.balance_rounded,
        Colors.blue,
        () => push(const ProportionsCalculatorPage()),
      ),
    ];
    if (isAthlete) {
      final myAthleteId = auth.user?.athleteId;
      if (myAthleteId != null && myAthleteId.isNotEmpty) {
        tiles.add(
          _quickTile(
            context,
            'Oś czasu',
            Icons.timeline_rounded,
            Colors.brown,
            () => push(
              AthleteTimelineScreen(
                athleteId: myAthleteId,
                subtitle: 'Mój profil',
              ),
            ),
          ),
        );
      }
      tiles.add(
        _quickTile(
          context,
          'Dziennik',
          Icons.book_outlined,
          Colors.teal,
          () => push(const TrainingLogScreen()),
        ),
      );
      tiles.add(
        _quickTile(
          context,
          'Sztanga',
          Icons.show_chart_rounded,
          Colors.deepOrange,
          () => push(const BarbellAnalysisScreen()),
        ),
      );
      tiles.add(
        _quickTile(
          context,
          'Regeneracja',
          Icons.spa_outlined,
          Colors.indigo,
          () => push(const RecoveryJournalScreen()),
        ),
      );
      tiles.add(
        _quickTile(
          context,
          'Osiągnięcia',
          Icons.military_tech_rounded,
          Colors.amber,
          () => push(const AthleteAchievementsScreen()),
        ),
      );
      tiles.add(
        _quickTile(
          context,
          'Plany',
          Icons.fitness_center_rounded,
          Colors.deepOrange,
          () => push(const AthleteTrainingPlansScreen()),
        ),
      );
      tiles.add(
        _quickTile(
          context,
          'Panel',
          Icons.bar_chart_rounded,
          Colors.purple,
          () => push(const AthletePortalScreen()),
        ),
      );
    }
    final canTrainerPlans = roles.contains('Trainer') ||
        roles.contains('Admin') ||
        roles.contains('SuperAdmin');
    if (isStaff) {
      tiles.add(
        _quickTile(
          context,
          'Starty',
          Icons.assignment_ind_rounded,
          Colors.cyan,
          () => push(const CompetitionAssignmentScreen()),
        ),
      );
    }
    if (canTrainerPlans) {
      tiles.add(
        _quickTile(
          context,
          'Trener — plany',
          Icons.edit_calendar_rounded,
          Colors.orange,
          () => push(const TrainerTrainingPlansScreen()),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SlaviaUi.sectionHeader(
          context,
          'Szybki dostęp',
          accent: primary,
          icon: Icons.bolt_rounded,
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: tiles.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (_, i) => tiles[i],
          ),
        ),
      ],
    );
  }

  Widget _quickTile(
    BuildContext context,
    String label,
    IconData icon,
    Color accent,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: 104,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: primary.withValues(alpha: 0.12)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color primary;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: SlaviaUi.statCardDecoration(context, primary),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
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

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final int index;
  final Color primary;
  final bool isDark;

  const _AnnouncementCard({
    required this.announcement,
    required this.index,
    required this.primary,
    required this.isDark,
  });

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
          border: Border.all(color: primary.withValues(alpha: 0.08)),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.lightImpact();
              final h = MediaQuery.sizeOf(context).height * 0.72;
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                showDragHandle: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(SlaviaUi.radiusXl),
                  ),
                ),
                builder: (ctx) => SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.title,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Text(
                                announcement.body,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.88),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
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
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          announcement.body,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
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

class _ClubPostsPreview extends StatelessWidget {
  const _ClubPostsPreview({required this.apiService, required this.primary});

  final ApiService apiService;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Aktualności klubu',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const ClubPostsScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Wszystkie',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<ClubPost>>(
          future: apiService.getClubPosts(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
              return Column(
                children: List.generate(
                  2,
                  (i) => _AnnouncementSkeleton(isDark: isDark),
                ),
              );
            }
            if (snap.hasError) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Nie udało się wczytać aktualności.',
                  style: GoogleFonts.outfit(fontSize: 13, color: cs.error),
                ),
              );
            }
            final list = (snap.data ?? []).take(3).toList();
            if (list.isEmpty) {
              return _EmptyState(
                icon: Icons.article_outlined,
                title: 'Brak aktualności',
                subtitle: 'Redakcyjne wpisy z klubu pojawią się tutaj.',
              );
            }
            return Column(
              children: list.asMap().entries.map((e) {
                final p = e.value;
                final excerpt = htmlToPlainText(p.content);
                final short =
                    excerpt.length > 88 ? '${excerpt.substring(0, 88)}…' : excerpt;
                return Padding(
                  padding: EdgeInsets.only(bottom: e.key < list.length - 1 ? 10 : 0),
                  child: Material(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
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
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primary.withValues(alpha: 0.1)),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: cs.tertiary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(Icons.newspaper_rounded, color: cs.tertiary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (short.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      short,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: cs.onSurface.withValues(alpha: 0.6),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _AnnouncementSkeleton extends StatelessWidget {
  final bool isDark;
  const _AnnouncementSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: base,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: 180,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(icon, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
