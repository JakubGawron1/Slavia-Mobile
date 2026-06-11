import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slavia_mobile/utils/chat_markdown.dart';

void main() {
  group('plainChatMarkdown', () {
    test('strips bold, italic, strike, code, links', () {
      const src = '**bold** __x__ ~~no~~ `c` [a](https://x.pl)';
      expect(plainChatMarkdown(src), 'bold x no c a');
    });
  });

  group('buildChatMarkdownSpans', () {
    test('produces bold and strike spans', () {
      const base = TextStyle(fontSize: 14);
      final spans = buildChatMarkdownSpans('**b** ~~s~~', base);
      expect(spans.length, greaterThan(1));
      final bold = spans.whereType<TextSpan>().firstWhere(
            (s) => s.style?.fontWeight == FontWeight.w700,
            orElse: () => throw StateError('no bold'),
          );
      expect(bold.text, 'b');
    });
  });
}
