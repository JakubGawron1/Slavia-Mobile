import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../services/api_service_ai_coach.dart';
import '../utils/chat_markdown.dart';

/// Trener AI — parity z WWW `OlympicCoachPanel` (bez załączników w v1 mobile).
class AiCoachScreen extends StatefulWidget {
  const AiCoachScreen({super.key, required this.isTrainerView});

  final bool isTrainerView;

  @override
  State<AiCoachScreen> createState() => _AiCoachScreenState();
}

class _AiCoachMessage {
  _AiCoachMessage({required this.role, required this.content});
  final String role;
  final String content;
}

class _AiCoachScreenState extends State<AiCoachScreen> {
  final _draftCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _messages = <_AiCoachMessage>[];
  String _mode = 'chat';
  bool _loading = false;
  bool _configured = true;
  String? _statusError;

  static const _modes = <String, String>{
    'chat': 'Czat',
    'plan': 'Plan',
    'supplements': 'Suplementacja',
    'recovery': 'Regeneracja',
  };

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _draftCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final api = context.read<ApiService>();
    try {
      final status = await api.getAiCoachStatus();
      if (!mounted) return;
      setState(() {
        _configured = status['configured'] == true;
        _statusError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _configured = false;
        _statusError = e.toString();
      });
    }
  }

  Future<void> _send() async {
    final text = _draftCtrl.text.trim();
    if (text.isEmpty || _loading || !_configured) return;

    final api = context.read<ApiService>();
    final auth = context.read<AuthProvider>();
    final history = _messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    setState(() {
      _messages.add(_AiCoachMessage(role: 'user', content: text));
      _loading = true;
      _draftCtrl.clear();
    });
    _scrollToEnd();

    try {
      final reply = await api.sendAiCoachChat(
        message: text,
        mode: _mode,
        history: history,
        useAthleteContext: widget.isTrainerView ? null : true,
        athleteId: widget.isTrainerView ? auth.user?.athleteId : null,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(_AiCoachMessage(role: 'assistant', content: reply));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _AiCoachMessage(
            role: 'assistant',
            content: 'Nie udało się uzyskać odpowiedzi: $e',
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToEnd();
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTrainerView ? 'Trener AI (kadra)' : 'Trener AI'),
      ),
      body: Column(
        children: [
          if (!_configured)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _statusError ?? 'Trener AI jest chwilowo niedostępny.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _modes.entries.map((e) {
                final selected = _mode == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: _loading
                        ? null
                        : (_) => setState(() => _mode = e.key),
                    selectedColor: primary.withValues(alpha: 0.2),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final msg = _messages[index];
                final isUser = msg.role == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * 0.85,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? primary.withValues(alpha: 0.15)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: isUser
                        ? Text(
                            msg.content,
                            style: GoogleFonts.outfit(fontSize: 14, height: 1.4),
                          )
                        : ChatMarkdownText(
                            msg.content,
                            style: GoogleFonts.outfit(fontSize: 14, height: 1.4),
                          ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _draftCtrl,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Napisz do trenera AI…',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _loading ? null : _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
