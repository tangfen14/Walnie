import 'package:baby_tracker/domain/entities/voice_normalization_config.dart';
import 'package:baby_tracker/infrastructure/voice/voice_text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const normalizer = VoiceTextNormalizer();

  VoiceNormalizationConfig buildConfig(List<VoiceNormalizationRule> rules) {
    return VoiceNormalizationConfig(
      version: 'test',
      ttlSeconds: 3600,
      updatedAt: DateTime(2026, 2, 21, 14, 0),
      fetchedAt: DateTime(2026, 2, 21, 14, 0),
      rules: rules,
    );
  }

  test('normalizes 轻微 to 亲喂 when feed context exists', () {
    final config = buildConfig(const <VoiceNormalizationRule>[
      VoiceNormalizationRule(
        id: 'q1',
        from: '轻微',
        to: '亲喂',
        scope: VoiceNormalizationScope.ruleOnly,
        priority: 100,
        contextKeywords: <String>['奶', '喂', '毫升', 'ml'],
        blockPhrases: <String>[],
        windowChars: 4,
      ),
    ]);

    final output = normalizer.normalizeForRule('轻微喂奶20分钟', config);
    expect(output, '亲喂喂奶20分钟');
  });

  test('normalizes 为 to 喂 with context keywords', () {
    final config = buildConfig(const <VoiceNormalizationRule>[
      VoiceNormalizationRule(
        id: 'w1',
        from: '为',
        to: '喂',
        scope: VoiceNormalizationScope.ruleOnly,
        priority: 100,
        contextKeywords: <String>['奶', '毫升', 'ml'],
        blockPhrases: <String>['因为', '认为', '为何', '作为', '为了'],
        windowChars: 3,
      ),
    ]);

    final output = normalizer.normalizeForRule('1点45分为奶50ml', config);
    expect(output, '1点45分喂奶50ml');
  });

  test('does not replace blocked phrase like 因为', () {
    final config = buildConfig(const <VoiceNormalizationRule>[
      VoiceNormalizationRule(
        id: 'w2',
        from: '为',
        to: '喂',
        scope: VoiceNormalizationScope.ruleOnly,
        priority: 100,
        contextKeywords: <String>['奶', '毫升', 'ml'],
        blockPhrases: <String>['因为', '认为', '为何', '作为', '为了'],
        windowChars: 3,
      ),
    ]);

    final output = normalizer.normalizeForRule('因为宝宝哭了', config);
    expect(output, '因为宝宝哭了');
  });

  test('applies higher priority and longer from first', () {
    final config = buildConfig(const <VoiceNormalizationRule>[
      VoiceNormalizationRule(
        id: 'short',
        from: '轻',
        to: '亲',
        scope: VoiceNormalizationScope.ruleOnly,
        priority: 100,
        contextKeywords: <String>['微'],
        blockPhrases: <String>[],
        windowChars: 3,
      ),
      VoiceNormalizationRule(
        id: 'long',
        from: '轻微',
        to: '亲喂',
        scope: VoiceNormalizationScope.ruleOnly,
        priority: 100,
        contextKeywords: <String>[],
        blockPhrases: <String>[],
        windowChars: 3,
      ),
    ]);

    final output = normalizer.normalizeForRule('轻微喂奶', config);
    expect(output, '亲喂喂奶');
  });
}
