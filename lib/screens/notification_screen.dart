import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/notification.dart';
import '../services/api_service.dart';
import '../services/push_notification_service.dart';
import '../ui/slavia_ui.dart';
import '../utils/network_feedback.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  var _didInitDeps = false;
  bool _loading = true;
  Object? _error;
  List<ClubNotification> _items = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitDeps) return;
    _didInitDeps = true;
    _fetch();
  }

  Future<void> _syncBadgeAndSeen() async {
    await PushNotificationService().refreshBadgeFromApi();
  }

  Future<void> _fetch() async {
    final api = Provider.of<ApiService>(context, listen: false);
    setState(() {
      if (_items.isEmpty) _loading = true;
      _error = null;
    });
    try {
      final list = await api.getNotifications();
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _fetch();
  }

  Future<void> _markRead(ClubNotification n) async {
    if (n.isRead) return;
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      await api.markNotificationRead(n.id);
      if (mounted) {
        await _fetch();
        unawaited(_syncBadgeAndSeen());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyNetworkError(e),
            style: GoogleFonts.outfit(),
          ),
        ),
      );
    }
  }

  Future<void> _markAll() async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      await api.markAllNotificationsRead();
      if (mounted) {
        HapticFeedback.lightImpact();
        await _fetch();
        unawaited(_syncBadgeAndSeen());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyNetworkError(e),
            style: GoogleFonts.outfit(),
          ),
        ),
      );
    }
  }

  Future<void> _deleteOne(ClubNotification n) async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      await api.deleteNotification(n.id);
      if (n.id.isNotEmpty) {
        await PushNotificationService().forgetNotificationIds([n.id]);
      }
      if (mounted) {
        setState(() => _items.removeWhere((x) => x.id == n.id));
        HapticFeedback.mediumImpact();
        unawaited(_syncBadgeAndSeen());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyNetworkError(e),
            style: GoogleFonts.outfit(),
          ),
        ),
      );
    }
  }

  Future<bool> _confirmDismissDelete(ClubNotification n) async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      await api.deleteNotification(n.id);
      if (n.id.isNotEmpty) {
        await PushNotificationService().forgetNotificationIds([n.id]);
      }
      unawaited(_syncBadgeAndSeen());
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlyNetworkError(e),
              style: GoogleFonts.outfit(),
            ),
          ),
        );
      }
      return false;
    }
  }

  Future<void> _confirmDeleteOne(ClubNotification n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Usunąć powiadomienie?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        content: Text(
          n.title,
          style: GoogleFonts.outfit(),
        ),
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
    if (ok == true && mounted) await _deleteOne(n);
  }

  Future<void> _confirmDeleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Usunąć wszystkie powiadomienia?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Tej operacji nie można cofnąć.',
          style: GoogleFonts.outfit(height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anuluj'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Usuń wszystkie'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final api = Provider.of<ApiService>(context, listen: false);
    final ids = _items.map((e) => e.id).where((id) => id.isNotEmpty).toList();
    try {
      await api.deleteAllNotifications();
      if (ids.isNotEmpty) {
        await PushNotificationService().forgetNotificationIds(ids);
      }
      if (mounted) {
        HapticFeedback.mediumImpact();
        await _fetch();
        unawaited(_syncBadgeAndSeen());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyNetworkError(e),
            style: GoogleFonts.outfit(),
          ),
        ),
      );
    }
  }

  Widget _buildNotificationTile(
    ClubNotification n,
    ColorScheme cs,
    int index,
  ) {
    final unread = !n.isRead;
    final card = Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
          border: Border.all(
            color: unread
                ? cs.primary.withValues(alpha: 0.35)
                : cs.outline.withValues(alpha: 0.12),
            width: unread ? 1.5 : 1,
          ),
          color: unread ? cs.primary.withValues(alpha: 0.06) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  await _markRead(n);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            SlaviaUi.radiusSm,
                          ),
                        ),
                        child: Icon(
                          unread
                              ? Icons.notifications_active_rounded
                              : Icons.notifications_none_rounded,
                          color: unread ? cs.primary : cs.outline,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: GoogleFonts.outfit(
                                fontWeight: unread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              n.body,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                height: 1.4,
                                color: cs.onSurface.withValues(
                                  alpha: 0.82,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('dd.MM.yyyy HH:mm').format(n.createdAt),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: cs.onSurface.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Usuń',
              icon: Icon(
                Icons.delete_outline_rounded,
                color: cs.outline,
              ),
              onPressed: () => _confirmDeleteOne(n),
            ),
          ],
        ),
      ),
    );

    return Dismissible(
      key: ValueKey('notif-${n.id}-$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: cs.error,
          borderRadius: BorderRadius.circular(SlaviaUi.radiusLg),
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: cs.onError,
          size: 28,
        ),
      ),
      confirmDismiss: (_) => _confirmDismissDelete(n),
      onDismissed: (_) {
        if (!mounted) return;
        setState(() => _items.removeWhere((x) => x.id == n.id));
        HapticFeedback.mediumImpact();
        unawaited(_syncBadgeAndSeen());
      },
      child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Powiadomienia',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Usuń wszystkie',
            icon: Icon(Icons.delete_sweep_outlined, color: cs.error),
            onPressed: _confirmDeleteAll,
          ),
          TextButton(
            onPressed: _markAll,
            child: Text(
              'Wszystkie przeczytane',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: cs.primary,
              ),
            ),
          ),
        ],
      ),
      body: _loading && _items.isEmpty
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _error != null && _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off_outlined, size: 52, color: cs.outline),
                        const SizedBox(height: 12),
                        Text(
                          friendlyNetworkError(_error!),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            height: 1.4,
                            color: cs.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _onRefresh,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Odśwież'),
                        ),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? RefreshIndicator(
                      color: cs.primary,
                      onRefresh: _onRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.sizeOf(context).height * 0.35,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_off_outlined,
                                    size: 56,
                                    color: cs.outline,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Brak powiadomień',
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: cs.primary,
                      onRefresh: _onRefresh,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final n = _items[index];
                          return _buildNotificationTile(n, cs, index);
                        },
                      ),
                    ),
    );
  }
}
