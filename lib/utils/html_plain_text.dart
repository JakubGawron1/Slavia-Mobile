import 'package:html/parser.dart' as html_parser;

/// Treść wpisów z WWW może być HTML — pokazujemy bezpieczny tekst (bez tagów).
String htmlToPlainText(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  if (!trimmed.contains('<')) return trimmed;
  try {
    final frag = html_parser.parseFragment(trimmed);
    final t = frag.text ?? '';
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  } catch (_) {
    return trimmed.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
