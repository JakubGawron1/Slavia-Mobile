import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/announcement.dart';
import '../services/api_service.dart';
import '../ui/slavia_ui.dart';

/// CRUD ogłoszeń — jak panel klubu na WWW (`Admin` / `SuperAdmin`).
class AnnouncementsManageScreen extends StatefulWidget {
  const AnnouncementsManageScreen({super.key});

  @override
  State<AnnouncementsManageScreen> createState() =>
      _AnnouncementsManageScreenState();
}

class _AnnouncementsManageScreenState extends State<AnnouncementsManageScreen> {
  Future<List<Announcement>>? _future;

  void _reload() {
    final api = Provider.of<ApiService>(context, listen: false);
    setState(() {
      _future = api.getAnnouncementsManage();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ogłoszenia',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editSheet(context, null),
        icon: const Icon(Icons.add_rounded),
        label: Text('Nowe', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _future;
        },
        child: FutureBuilder<List<Announcement>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting &&
                !snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: cs.error),
                        const SizedBox(height: 12),
                        Text(
                          'Brak uprawnień lub błąd sieci.\n'
                          'Ogłoszenia mogą edytować Administrator i SuperAdmin.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _reload,
                          child: const Text('Spróbuj ponownie'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            final items = snap.data ?? [];
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.35,
                    child: Center(
                      child: Text(
                        'Brak ogłoszeń — dodaj pierwsze.',
                        style: GoogleFonts.outfit(
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final a = items[i];
                return Material(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
                    onTap: () => _editSheet(context, a),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
                        border: Border.all(
                          color: cs.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  a.title,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded),
                                onPressed: () => _confirmDelete(context, a),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (a.pinned)
                                Chip(
                                  label: Text(
                                    'Przypięte',
                                    style: GoogleFonts.outfit(fontSize: 11),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              Chip(
                                label: Text(
                                  a.published ? 'Opublikowane' : 'Szkic',
                                  style: GoogleFonts.outfit(fontSize: 11),
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              Chip(
                                label: Text(
                                  'kolejność ${a.sortOrder}',
                                  style: GoogleFonts.outfit(fontSize: 11),
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('dd.MM.yyyy HH:mm').format(a.createdAt),
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            a.body,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              height: 1.35,
                              color: cs.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
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

  Future<void> _confirmDelete(BuildContext context, Announcement a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Usunąć ogłoszenie?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        content: Text(a.title, style: GoogleFonts.outfit()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      await api.deleteAnnouncement(a.id);
      messenger.showSnackBar(
        SnackBar(content: Text('Usunięto', style: GoogleFonts.outfit())),
      );
      _reload();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Nie udało się usunąć', style: GoogleFonts.outfit()),
        ),
      );
    }
  }

  Future<void> _editSheet(BuildContext context, Announcement? existing) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final bodyCtrl = TextEditingController(text: existing?.body ?? '');
    var pinned = existing?.pinned ?? false;
    var published = existing?.published ?? true;
    var sortOrder = existing?.sortOrder ?? 0;

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      existing == null
                          ? 'Nowe ogłoszenie'
                          : 'Edycja ogłoszenia',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tytuł',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bodyCtrl,
                      minLines: 5,
                      maxLines: 12,
                      decoration: const InputDecoration(
                        labelText: 'Treść',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text(
                        'Przypięte',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                      value: pinned,
                      onChanged: (v) => setModal(() => pinned = v),
                    ),
                    SwitchListTile(
                      title: Text(
                        'Opublikowane',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        'Szkic nie jest widoczny na liście publicznej',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Theme.of(ctx)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.55),
                        ),
                      ),
                      value: published,
                      onChanged: (v) => setModal(() => published = v),
                    ),
                    Row(
                      children: [
                        Text(
                          'Kolejność sortowania',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => setModal(() {
                            sortOrder =
                                (sortOrder - 1).clamp(0, 9999).toInt();
                          }),
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        Text('$sortOrder'),
                        IconButton(
                          onPressed: () => setModal(() {
                            sortOrder =
                                (sortOrder + 1).clamp(0, 9999).toInt();
                          }),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () async {
                        final t = titleCtrl.text.trim();
                        final b = bodyCtrl.text.trim();
                        if (t.isEmpty || b.isEmpty) return;
                        final nav = Navigator.of(ctx);
                        try {
                          if (existing == null) {
                            await api.createAnnouncement(
                              title: t,
                              body: b,
                              pinned: pinned,
                              sortOrder: sortOrder,
                              published: published,
                            );
                          } else {
                            await api.updateAnnouncement(
                              existing.id,
                              title: t,
                              body: b,
                              pinned: pinned,
                              sortOrder: sortOrder,
                              published: published,
                            );
                          }
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Zapisano',
                                style: GoogleFonts.outfit(),
                              ),
                            ),
                          );
                          _reload();
                        } catch (_) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Błąd zapisu',
                                style: GoogleFonts.outfit(),
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Zapisz',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    titleCtrl.dispose();
    bodyCtrl.dispose();
  }
}
