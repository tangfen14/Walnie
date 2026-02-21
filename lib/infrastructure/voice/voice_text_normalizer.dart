import 'package:baby_tracker/domain/entities/voice_normalization_config.dart';

class VoiceTextNormalizer {
  const VoiceTextNormalizer();

  String normalizeForRule(String raw, VoiceNormalizationConfig config) {
    if (raw.isEmpty) {
      return raw;
    }

    var normalized = raw;
    final rules = config.rulesForRuleParsing.toList(growable: false)
      ..sort((a, b) {
        final byPriority = b.priority.compareTo(a.priority);
        if (byPriority != 0) {
          return byPriority;
        }
        return b.from.length.compareTo(a.from.length);
      });

    for (final rule in rules) {
      normalized = _applyRule(normalized, rule);
    }

    return normalized;
  }

  String _applyRule(String source, VoiceNormalizationRule rule) {
    if (rule.from.isEmpty || rule.from == rule.to) {
      return source;
    }

    for (final phrase in rule.blockPhrases) {
      if (phrase.isNotEmpty && source.contains(phrase)) {
        return source;
      }
    }

    final needsContext =
        rule.contextKeywords.isNotEmpty || rule.from.runes.length == 1;
    if (!needsContext) {
      return source.replaceAll(rule.from, rule.to);
    }

    final contextKeywords = rule.contextKeywords.isNotEmpty
        ? rule.contextKeywords
        : <String>[rule.to];
    final windowChars = rule.windowChars <= 0 ? 3 : rule.windowChars;

    final firstMatch = source.indexOf(rule.from);
    if (firstMatch < 0) {
      return source;
    }

    final buffer = StringBuffer();
    var cursor = 0;
    var index = firstMatch;
    while (index >= 0) {
      buffer.write(source.substring(cursor, index));

      final matchEnd = index + rule.from.length;
      final hasContext = _hasContext(
        source: source,
        matchStart: index,
        matchEnd: matchEnd,
        contextKeywords: contextKeywords,
        windowChars: windowChars,
      );

      if (hasContext) {
        buffer.write(rule.to);
      } else {
        buffer.write(rule.from);
      }

      cursor = matchEnd;
      index = source.indexOf(rule.from, cursor);
    }

    if (cursor < source.length) {
      buffer.write(source.substring(cursor));
    }
    return buffer.toString();
  }

  bool _hasContext({
    required String source,
    required int matchStart,
    required int matchEnd,
    required List<String> contextKeywords,
    required int windowChars,
  }) {
    final start = (matchStart - windowChars).clamp(0, source.length);
    final end = (matchEnd + windowChars).clamp(0, source.length);
    final snippet = source.substring(start, end);
    for (final keyword in contextKeywords) {
      if (keyword.isNotEmpty && snippet.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
