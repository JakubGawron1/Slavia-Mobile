import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Inline Markdown subset — parity with `@slavia/shared` `markdownInline.ts`.
///
/// [plainChatMarkdown] strips markup for plain [Text]; [ChatMarkdownText] renders
/// bold, italic, strike, code and http(s) links in chat bubbles.

final _codeRe = RegExp(r'`([^`]+)`');
final _linkRe = RegExp(r'\[([^\]]+)\]\((https?:\/\/[^\s)]+)\)');
final _boldStarRe = RegExp(r'\*\*([^*]+)\*\*');
final _boldUnderRe = RegExp(r'__([^_]+)__');
final _strikeRe = RegExp(r'~~([^~]+)~~');
final _italicStarRe = RegExp(r'(?<!\*)\*([^*]+)\*(?!\*)');
final _italicUnderRe = RegExp(r'(?<!_)_([^_]+)_(?!_)');

String _stripPattern(String text, RegExp re) =>
    text.replaceAllMapped(re, (m) => m.group(1) ?? '');

/// Plain-text fallback — strips inline MD (user messages, notifications).
String plainChatMarkdown(String source) {
  var text = source;
  text = _stripPattern(text, _codeRe);
  text = _stripPattern(text, _linkRe);
  text = _stripPattern(text, _boldStarRe);
  text = _stripPattern(text, _boldUnderRe);
  text = _stripPattern(text, _strikeRe);
  text = _stripPattern(text, _italicStarRe);
  text = _stripPattern(text, _italicUnderRe);
  return text;
}

class _MdToken {
  const _MdToken(this.start, this.end, this.child);

  final int start;
  final int end;
  final InlineSpan child;
}

/// Rich inline markdown for assistant / peer chat bubbles.
class ChatMarkdownText extends StatelessWidget {
  const ChatMarkdownText(this.source, {super.key, this.style});

  final String source;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    return Text.rich(
      TextSpan(children: buildChatMarkdownSpans(source, base)),
      style: base,
    );
  }
}

List<InlineSpan> buildChatMarkdownSpans(String source, TextStyle base) {
  if (source.isEmpty) return [TextSpan(text: '', style: base)];

  final tokens = <_MdToken>[];
  void collect(RegExp re, InlineSpan Function(RegExpMatch) build) {
    for (final m in re.allMatches(source)) {
      tokens.add(_MdToken(m.start, m.end, build(m)));
    }
  }

  collect(_codeRe, (m) => TextSpan(
        text: m.group(1),
        style: base.copyWith(
          fontFamily: 'monospace',
          backgroundColor: base.color?.withValues(alpha: 0.08),
        ),
      ));
  collect(_linkRe, (m) {
    final label = m.group(1) ?? '';
    final href = m.group(2) ?? '';
    return TextSpan(
      text: label,
      style: base.copyWith(
        color: base.color?.withValues(alpha: 0.95),
        decoration: TextDecoration.underline,
        decorationColor: base.color?.withValues(alpha: 0.5),
      ),
      recognizer: TapGestureRecognizer()
        ..onTap = () {
          final uri = Uri.tryParse(href);
          if (uri != null) unawaited(launchUrl(uri, mode: LaunchMode.externalApplication));
        },
    );
  });
  collect(_boldStarRe, (m) => TextSpan(text: m.group(1), style: base.copyWith(fontWeight: FontWeight.w700)));
  collect(_boldUnderRe, (m) => TextSpan(text: m.group(1), style: base.copyWith(fontWeight: FontWeight.w700)));
  collect(_strikeRe, (m) => TextSpan(
        text: m.group(1),
        style: base.copyWith(decoration: TextDecoration.lineThrough),
      ));
  collect(_italicStarRe, (m) => TextSpan(text: m.group(1), style: base.copyWith(fontStyle: FontStyle.italic)));
  collect(_italicUnderRe, (m) => TextSpan(text: m.group(1), style: base.copyWith(fontStyle: FontStyle.italic)));

  tokens.sort((a, b) => a.start.compareTo(b.start));

  final spans = <InlineSpan>[];
  var cursor = 0;
  for (final t in tokens) {
    if (t.start < cursor) continue;
    if (t.start > cursor) {
      spans.add(TextSpan(text: source.substring(cursor, t.start), style: base));
    }
    spans.add(t.child);
    cursor = t.end;
  }
  if (cursor < source.length) {
    spans.add(TextSpan(text: source.substring(cursor), style: base));
  }
  return spans.isEmpty ? [TextSpan(text: source, style: base)] : spans;
}
