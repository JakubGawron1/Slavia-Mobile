import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../models/auth.dart';
import '../models/athlete.dart';
import '../models/chat.dart';
import '../services/api_service.dart';
import '../ui/slavia_ui.dart';

/// Czat trener–zawodnik 1:1 (jak `/chat` na WWW).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatThread> _threads = [];
  List<ChatMessage> _messages = [];
  String? _activeThreadId;
  bool _loadingThreads = true;
  bool _loadingMessages = false;
  final _draftCtrl = TextEditingController();
  final _titleDraftCtrl = TextEditingController();
  final _newThreadTitleCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  bool _canStartThread(AuthUser? u) {
    final r = u?.roles ?? [];
    return r.contains('Trainer') || r.contains('SuperAdmin');
  }

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  @override
  void dispose() {
    _draftCtrl.dispose();
    _titleDraftCtrl.dispose();
    _newThreadTitleCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadThreads() async {
    final api = Provider.of<ApiService>(context, listen: false);
    setState(() => _loadingThreads = true);
    try {
      final list = await api.getChatThreads();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      if (mounted) {
        setState(() {
          _threads = list;
          _loadingThreads = false;
          if (_activeThreadId != null &&
              !_threads.any((t) => t.id == _activeThreadId)) {
            _activeThreadId = null;
            _messages = [];
          }
          if (_activeThreadId == null && _threads.isNotEmpty) {
            _activeThreadId = _threads.first.id;
          }
        });
        if (_activeThreadId != null) await _loadMessages();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingThreads = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Wątki: $e')));
      }
    }
  }

  Future<void> _loadMessages() async {
    final id = _activeThreadId;
    if (id == null) return;
    final api = Provider.of<ApiService>(context, listen: false);
    setState(() => _loadingMessages = true);
    try {
      final list = await api.getChatMessages(id);
      if (mounted) {
        setState(() {
          _messages = list;
          _loadingMessages = false;
          var title = '';
          for (final x in _threads) {
            if (x.id == id) {
              title = x.title?.trim() ?? '';
              break;
            }
          }
          _titleDraftCtrl.text = title;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingMessages = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Wiadomości: $e')));
      }
    }
  }

  Future<void> _send() async {
    final text = _draftCtrl.text.trim();
    final id = _activeThreadId;
    if (text.isEmpty || id == null) return;
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      await api.sendChatMessage(id, text);
      _draftCtrl.clear();
      await _loadThreads();
      await _loadMessages();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Wysyłka: $e')));
    }
  }

  Future<void> _saveTitle() async {
    final id = _activeThreadId;
    if (id == null) return;
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      await api.updateChatThreadTitle(id, _titleDraftCtrl.text);
      await _loadThreads();
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Zapisano tytuł')));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteThread() async {
    final id = _activeThreadId;
    if (id == null) return;
    final t = _threads.firstWhere((x) => x.id == id);
    final title = t.title?.trim().isNotEmpty == true
        ? t.title!.trim()
        : 'Konwersacja bez tytułu';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Usunąć wątek?'),
        content: Text('„$title” — wszystkie wiadomości zostaną usunięte.'),
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
    if (ok != true) return;
    if (!mounted) return;
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      await api.deleteChatThread(id);
      if (mounted) {
        setState(() {
          _activeThreadId = null;
          _messages = [];
        });
        await _loadThreads();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usunięto wątek')));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _openNewThreadSheet() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    List<Athlete> athletes = [];
    try {
      athletes = await api.getAthletesAdmin();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lista zawodników: $e')));
      return;
    }
    athletes = athletes
        .where((a) => a.userId != null && a.userId!.isNotEmpty)
        .toList();
    String? selectedAthleteId;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Nowy wątek',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Zawodnik',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InputDecorator(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text('Wybierz zawodnika z kontem'),
                          value: selectedAthleteId,
                          items: athletes
                              .map(
                                (a) => DropdownMenuItem(
                                  value: a.id,
                                  child: Text(
                                    a.fullName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setSheet(() => selectedAthleteId = v),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _newThreadTitleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Tytuł konwersacji',
                        hintText: 'np. Plan na zawody',
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () async {
                        final aid = selectedAthleteId;
                        if (aid == null) return;
                        final ath = athletes.firstWhere((a) => a.id == aid);
                        final uid = ath.userId;
                        if (uid == null || uid.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('Brak konta użytkownika'),
                            ),
                          );
                          return;
                        }
                        try {
                          final thread = await api.openChatThread(
                            athleteUserId: uid,
                            trainerUserId: auth.user!.id,
                            title: _newThreadTitleCtrl.text.trim().isEmpty
                                ? null
                                : _newThreadTitleCtrl.text.trim(),
                          );
                          _newThreadTitleCtrl.clear();
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            setState(() => _activeThreadId = thread.id);
                            await _loadThreads();
                            if (!mounted) return;
                            await _loadMessages();
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(
                              ctx,
                            ).showSnackBar(SnackBar(content: Text('$e')));
                          }
                        }
                      },
                      child: const Text('Otwórz wątek'),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _fmtTs(String ts) {
    try {
      final d = DateTime.parse(ts);
      return DateFormat('dd.MM. HH:mm', 'pl_PL').format(d.toLocal());
    } catch (_) {
      return ts;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final cs = Theme.of(context).colorScheme;
    final selfId = auth.user?.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Czat trener–zawodnik',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
      ),
      body: _loadingThreads
          ? const Center(child: CircularProgressIndicator())
          : Row(
              children: [
                SizedBox(
                  width: MediaQuery.sizeOf(context).width < 600 ? 140 : 200,
                  child: Column(
                    children: [
                      if (_canStartThread(auth.user)) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: _openNewThreadSheet,
                              icon: const Icon(
                                Icons.add_comment_outlined,
                                size: 18,
                              ),
                              label: const Text('Nowy'),
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadThreads,
                          child: _threads.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(
                                      height:
                                          MediaQuery.sizeOf(context).height *
                                          0.15,
                                    ),
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          'Brak wątków',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.outfit(
                                            color: cs.onSurface.withValues(
                                              alpha: 0.6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.builder(
                                  itemCount: _threads.length,
                                  itemBuilder: (context, i) {
                                    final t = _threads[i];
                                    final sel = t.id == _activeThreadId;
                                    return Material(
                                      color: sel
                                          ? cs.primary.withValues(alpha: 0.12)
                                          : Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          setState(
                                            () => _activeThreadId = t.id,
                                          );
                                          _loadMessages();
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 10,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                t.title?.trim().isNotEmpty ==
                                                        true
                                                    ? t.title!
                                                    : 'Bez tytułu',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                t.updatedAt.length >= 16
                                                    ? t.updatedAt.substring(
                                                        0,
                                                        16,
                                                      )
                                                    : t.updatedAt,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 10,
                                                  color: cs.onSurface
                                                      .withValues(alpha: 0.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _activeThreadId == null
                      ? Center(
                          child: Text(
                            'Wybierz wątek po lewej',
                            style: GoogleFonts.outfit(
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _titleDraftCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Tytuł konwersacji',
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _saveTitle,
                                    icon: const Icon(Icons.save_outlined),
                                    tooltip: 'Zapisz tytuł',
                                  ),
                                  IconButton(
                                    onPressed: _deleteThread,
                                    icon: const Icon(Icons.delete_outline),
                                    color: cs.error,
                                    tooltip: 'Usuń wątek',
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: _loadingMessages
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : ListView.builder(
                                      controller: _scrollCtrl,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      itemCount: _messages.length,
                                      itemBuilder: (context, i) {
                                        final m = _messages[i];
                                        final mine = m.senderUserId == selfId;
                                        return Align(
                                          alignment: mine
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            constraints: BoxConstraints(
                                              maxWidth:
                                                  MediaQuery.sizeOf(
                                                    context,
                                                  ).width *
                                                  0.72,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                            decoration: BoxDecoration(
                                              color: mine
                                                  ? cs.primary.withValues(
                                                      alpha: 0.18,
                                                    )
                                                  : cs.surfaceContainerHighest
                                                        .withValues(alpha: 0.9),
                                              borderRadius: BorderRadius.only(
                                                topLeft: const Radius.circular(
                                                  16,
                                                ),
                                                topRight: const Radius.circular(
                                                  16,
                                                ),
                                                bottomLeft: Radius.circular(
                                                  mine ? 16 : 4,
                                                ),
                                                bottomRight: Radius.circular(
                                                  mine ? 4 : 16,
                                                ),
                                              ),
                                              border: Border.all(
                                                color: cs.outline.withValues(
                                                  alpha: 0.15,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: mine
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                              children: [
                                                if (!mine &&
                                                    (m
                                                            .senderUsername
                                                            ?.isNotEmpty ??
                                                        false))
                                                  Text(
                                                    m.senderUsername!,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: cs.primary,
                                                    ),
                                                  ),
                                                Text(
                                                  m.body,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14,
                                                    height: 1.35,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _fmtTs(m.createdAt),
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10,
                                                    color: cs.onSurface
                                                        .withValues(alpha: 0.5),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                8,
                                4,
                                8,
                                MediaQuery.paddingOf(context).bottom + 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _draftCtrl,
                                      minLines: 1,
                                      maxLines: 4,
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: (_) => _send(),
                                      decoration: InputDecoration(
                                        hintText: 'Napisz wiadomość…',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            SlaviaUi.radiusMd,
                                          ),
                                        ),
                                        filled: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: _send,
                                    child: const Icon(Icons.send_rounded),
                                  ),
                                ],
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
