import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/gallery_photo.dart';
import '../services/api_service.dart';
import '../ui/slavia_ui.dart';
import '../utils/resolve_media_url.dart';

/// Galeria z `/api/gallery` — jak sekcja „Galeria” na stronie klubu.
class ClubGalleryScreen extends StatefulWidget {
  const ClubGalleryScreen({super.key});

  @override
  State<ClubGalleryScreen> createState() => _ClubGalleryScreenState();
}

class _ClubGalleryScreenState extends State<ClubGalleryScreen> {
  Future<List<GalleryPhoto>>? _future;

  Future<void> _reload() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final f = api.getGalleryPhotos();
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

  Future<void> _openExternal(String url) async {
    final u = Uri.tryParse(url);
    if (u == null) return;
    final ok = await launchUrl(u, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się otworzyć pliku.', style: GoogleFonts.outfit())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Galeria klubu', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
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
        child: FutureBuilder<List<GalleryPhoto>>(
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
                    'Nie udało się wczytać galerii.',
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
            final photos = snap.data ?? [];
            final images = photos.where((p) => !p.isVideo).toList();
            final videos = photos.where((p) => p.isVideo).toList();

            if (photos.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 48),
                  Icon(Icons.photo_library_outlined, size: 56, color: cs.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Galeria jest pusta',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Po dodaniu zdjęć w panelu klubu zobaczysz je tutaj.',
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

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (videos.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Filmy',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final v = videos[i];
                        final url = resolveClubMediaUrl(v.imageUrl);
                        return Padding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, i < videos.length - 1 ? 8 : 0),
                          child: Material(
                          color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
                            onTap: () => _openExternal(url),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: cs.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.play_circle_fill_rounded, color: cs.primary, size: 32),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          v.caption?.trim().isNotEmpty == true
                                              ? v.caption!.trim()
                                              : 'Odtwórz wideo',
                                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Otwiera się w zewnętrznej aplikacji',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: cs.onSurface.withValues(alpha: 0.55),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.open_in_new_rounded, size: 18, color: cs.outline),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                      },
                      childCount: videos.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ],
                if (images.isNotEmpty) ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Zdjęcia',
                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final p = images[index];
                          final url = resolveClubMediaUrl(p.imageUrl);
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(SlaviaUi.radiusMd),
                            child: Material(
                              color: cs.surfaceContainerHighest,
                              child: InkWell(
                                onTap: () {
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      fullscreenDialog: true,
                                      builder: (ctx) => _ClubGalleryPhotoPage(
                                        imageUrl: url,
                                        caption: p.caption,
                                      ),
                                    ),
                                  );
                                },
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Icon(Icons.broken_image_outlined, color: cs.outline),
                                      ),
                                    ),
                                    if (p.caption != null && p.caption!.trim().isNotEmpty)
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                          color: Colors.black54,
                                          child: Text(
                                            p.caption!.trim(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.outfit(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: images.length,
                      ),
                    ),
                  ),
                ],
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ClubGalleryPhotoPage extends StatelessWidget {
  const _ClubGalleryPhotoPage({required this.imageUrl, this.caption});

  final String imageUrl;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cap = caption?.trim();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Podgląd', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.broken_image_outlined, size: 48, color: cs.outline),
                ),
              ),
            ),
          ),
          if (cap != null && cap.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Text(
                cap,
                style: GoogleFonts.outfit(fontSize: 15, height: 1.4, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
