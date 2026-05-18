import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/athlete_timeline_item.dart';
import '../services/api_service.dart';
import '../ui/slavia_ui.dart';
import '../utils/network_feedback.dart';
import '../services/result_share_service.dart';

/// Oś czasu zawodnika — ta sama logika co `/athlete/timeline` na WWW (API).
class AthleteTimelineScreen extends StatefulWidget {
  final String athleteId;
  final String? subtitle;

  const AthleteTimelineScreen({
    super.key,
    required this.athleteId,
    this.subtitle,
  });

  @override
  State<AthleteTimelineScreen> createState() => _AthleteTimelineScreenState();
}

class _AthleteTimelineScreenState extends State<AthleteTimelineScreen> {
  Future<List<AthleteTimelineItem>>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    final api = Provider.of<ApiService>(context, listen: false);
    setState(
      () => _future = api.getAthleteTimeline(widget.athleteId),
    );
  }

  IconData _iconForKind(String kind) {
    switch (kind) {
      case 'result':
        return Icons.emoji_events_rounded;
      case 'attendance':
        return Icons.event_available_rounded;
      case 'training_log':
        return Icons.book_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _colorForKind(String kind, ColorScheme cs) {
    switch (kind) {
      case 'result':
        return cs.tertiary;
      case 'attendance':
        return cs.secondary;
      case 'training_log':
        return cs.primary;
      default:
        return cs.outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subtitle != null && widget.subtitle!.trim().isNotEmpty
              ? 'Oś czasu · ${widget.subtitle!.trim()}'
              : 'Oś czasu',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: _future == null
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : FutureBuilder<List<AthleteTimelineItem>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: cs.primary),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              size: 48, color: cs.outline),
                          const SizedBox(height: 12),
                          Text(
                            friendlyNetworkError(snapshot.error!),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(height: 1.4),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Odśwież'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'Brak wpisów na osi czasu.',
                      style: GoogleFonts.outfit(
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  color: cs.primary,
                  onRefresh: () async {
                    _reload();
                    await _future;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final it = items[index];
                      final accent = _colorForKind(it.kind, cs);
                      final when = DateFormat(
                        'dd.MM.yyyy HH:mm',
                        'pl_PL',
                      ).format(it.at.toLocal());

                      return Material(
                        color: cs.surface,
                        borderRadius:
                            BorderRadius.circular(SlaviaUi.radiusLg),
                        child: InkWell(
                          borderRadius:
                              BorderRadius.circular(SlaviaUi.radiusLg),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            showModalBottomSheet<void>(
                              context: context,
                              showDragHandle: true,
                              backgroundColor: cs.surface,
                              builder: (ctx) => Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  24,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      it.title,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      when,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    if (it.detail.trim().isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      SelectableText(
                                        it.detail,
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          height: 1.45,
                                        ),
                                      ),
                                    ],
                                    if (it.kind == 'result') ...[
                                      const SizedBox(height: 16),
                                      FilledButton.icon(
                                        onPressed: () async {
                                          Navigator.pop(ctx);
                                          await ResultShareService.instance.shareResultCard(
                                            context: context,
                                            athleteName: widget.subtitle ?? 'Zawodnik',
                                            title: it.title,
                                            detail: it.detail,
                                            dateLabel: when,
                                          );
                                        },
                                        icon: const Icon(Icons.ios_share_rounded),
                                        label: const Text('Udostępnij jako grafikę'),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _iconForKind(it.kind),
                                    color: accent,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        it.title,
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        when,
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.45),
                                        ),
                                      ),
                                      if (it.detail.trim().isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          it.detail,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            height: 1.35,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.75),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
