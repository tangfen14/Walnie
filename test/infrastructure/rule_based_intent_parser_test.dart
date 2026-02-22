import 'package:baby_tracker/domain/entities/voice_intent.dart';
import 'package:baby_tracker/domain/entities/voice_normalization_config.dart';
import 'package:baby_tracker/infrastructure/voice/rule_based_intent_parser.dart';
import 'package:baby_tracker/infrastructure/voice/voice_text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final parser = RuleBasedIntentParser(
    nowProvider: () => DateTime(2026, 2, 21, 9, 5),
  );
  final normalizer = const VoiceTextNormalizer();

  test('parses feeding command with amount and relative time', () {
    final intent = parser.parse('10分钟前喂奶60毫升');

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'feed');
    expect(intent.payload['amountMl'], 60);
    expect(intent.payload['occurredAt'], isA<String>());
  });

  test('parses reminder command', () {
    final intent = parser.parse('提醒我每3小时喂奶');

    expect(intent.intentType, VoiceIntentType.setReminder);
    expect(intent.payload['intervalHours'], 3);
  });

  test('parses query command', () {
    final intent = parser.parse('今天喂了几次');

    expect(intent.intentType, VoiceIntentType.querySummary);
    expect(intent.payload['query'], contains('今天'));
  });

  test('parses feeding command with HH:mm time', () {
    final intent = parser.parse('3:00喂奶50毫升');
    final occurredAt = DateTime.parse(intent.payload['occurredAt'] as String);

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'feed');
    expect(intent.payload['amountMl'], 50);
    expect(occurredAt.hour, 3);
    expect(occurredAt.minute, 0);
  });

  test('parses feeding command with full-width HH：mm time', () {
    final intent = parser.parse('今天3：20喂奶');
    final occurredAt = DateTime.parse(intent.payload['occurredAt'] as String);

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'feed');
    expect(occurredAt.hour, 3);
    expect(occurredAt.minute, 20);
  });

  test('parses feeding command with HH.mm time', () {
    final intent = parser.parse('5.02炫了70毫升');
    final occurredAt = DateTime.parse(intent.payload['occurredAt'] as String);

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'feed');
    expect(intent.payload['amountMl'], 70);
    expect(occurredAt.hour, 5);
    expect(occurredAt.minute, 2);
  });

  test('parses feeding command with full-width HH．mm time', () {
    final intent = parser.parse('5．02喂奶');
    final occurredAt = DateTime.parse(intent.payload['occurredAt'] as String);

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'feed');
    expect(occurredAt.hour, 5);
    expect(occurredAt.minute, 2);
  });

  test('parses pump command with amount and duration', () {
    final intent = parser.parse('吸奶25分钟120毫升');
    final start = DateTime.parse(intent.payload['pumpStartAt'] as String);
    final end = DateTime.parse(intent.payload['pumpEndAt'] as String);

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'pump');
    expect(intent.payload['amountMl'], 120);
    expect(intent.payload['durationMin'], 25);
    expect(end.isAfter(start), isTrue);
  });

  test('parses diaper command with keywords', () {
    final intent = parser.parse('刚刚换尿布了');

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'diaper');
  });

  test('parses feed command with requested colloquial keywords', () {
    const feedSamples = <String>[
      '17点炫了60ml',
      '8点吃了90毫升',
      '刚刚喂了30毫升',
      '凌晨喝了50ml',
      '半夜顿顿顿120毫升',
      '现在喂养70毫升',
    ];

    for (final sample in feedSamples) {
      final intent = parser.parse(sample);
      expect(
        intent.payload['eventType'],
        'feed',
        reason: 'sample "$sample" should map to feed',
      );
    }
  });

  test('parses diaper command with 纸尿裤 keyword', () {
    final intent = parser.parse('8点换了纸尿裤');

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'diaper');
  });

  test('maps pee keyword to diaper event with pee status', () {
    final intent = parser.parse('刚刚尿尿了');

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'diaper');
    expect(intent.payload['diaperStatus'], 'pee');
    expect(intent.payload['changedDiaper'], true);
  });

  test('maps poop keyword to diaper event with poop status', () {
    final intent = parser.parse('刚刚便便了');

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'diaper');
    expect(intent.payload['diaperStatus'], 'poop');
    expect(intent.payload['changedDiaper'], true);
  });

  test('does not misclassify drink water as feed', () {
    final intent = parser.parse('17点喝水200ml');

    expect(intent.intentType, VoiceIntentType.unknown);
  });

  test('does not misclassify taking medicine as feed', () {
    final intent = parser.parse('刚刚吃药了');

    expect(intent.intentType, VoiceIntentType.unknown);
  });

  test('defaults to today and infers afternoon for non-24h clock', () {
    final afternoonParser = RuleBasedIntentParser(
      nowProvider: () => DateTime(2026, 2, 21, 14, 5),
    );

    final intent = afternoonParser.parse('1点45分喂奶50ml');
    final occurredAt = DateTime.parse(intent.payload['occurredAt'] as String);

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'feed');
    expect(occurredAt.year, 2026);
    expect(occurredAt.month, 2);
    expect(occurredAt.day, 21);
    expect(occurredAt.hour, 13);
    expect(occurredAt.minute, 45);
  });

  test('infers afternoon for dot clock when now is afternoon', () {
    final afternoonParser = RuleBasedIntentParser(
      nowProvider: () => DateTime(2026, 2, 21, 14, 5),
    );

    final intent = afternoonParser.parse('1.45喂奶50ml');
    final occurredAt = DateTime.parse(intent.payload['occurredAt'] as String);

    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'feed');
    expect(occurredAt.year, 2026);
    expect(occurredAt.month, 2);
    expect(occurredAt.day, 21);
    expect(occurredAt.hour, 13);
    expect(occurredAt.minute, 45);
  });

  test('keeps explicit month and day when provided', () {
    final afternoonParser = RuleBasedIntentParser(
      nowProvider: () => DateTime(2026, 2, 21, 14, 5),
    );

    final intent = afternoonParser.parse('2月20日1点45分喂奶50ml');
    final occurredAt = DateTime.parse(intent.payload['occurredAt'] as String);

    expect(occurredAt.year, 2026);
    expect(occurredAt.month, 2);
    expect(occurredAt.day, 20);
    expect(occurredAt.hour, 13);
    expect(occurredAt.minute, 45);
  });

  test('respects explicit morning marker for 12-hour clock', () {
    final afternoonParser = RuleBasedIntentParser(
      nowProvider: () => DateTime(2026, 2, 21, 14, 5),
    );

    final intent = afternoonParser.parse('上午1点45分喂奶50ml');
    final occurredAt = DateTime.parse(intent.payload['occurredAt'] as String);

    expect(occurredAt.year, 2026);
    expect(occurredAt.month, 2);
    expect(occurredAt.day, 21);
    expect(occurredAt.hour, 1);
    expect(occurredAt.minute, 45);
  });

  test('parses feed after normalizing 为 to 喂 in feed context', () {
    final normalized = normalizer.normalizeForRule(
      '1点45分为奶50ml',
      VoiceNormalizationConfig.fallback(now: DateTime(2026, 2, 21, 14, 0)),
    );
    final intent = parser.parse(normalized);

    expect(normalized, '1点45分喂奶50ml');
    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'feed');
    expect(intent.payload['amountMl'], 50);
  });

  test('parses feed after normalizing 轻微 to 亲喂 in feed context', () {
    final normalized = normalizer.normalizeForRule(
      '轻微奶20分钟',
      VoiceNormalizationConfig.fallback(now: DateTime(2026, 2, 21, 14, 0)),
    );
    final intent = parser.parse(normalized);

    expect(normalized, '亲喂奶20分钟');
    expect(intent.intentType, VoiceIntentType.createEvent);
    expect(intent.payload['eventType'], 'feed');
  });

  test('does not normalize blocked phrase 因为', () {
    final normalized = normalizer.normalizeForRule(
      '因为宝宝哭了',
      VoiceNormalizationConfig.fallback(now: DateTime(2026, 2, 21, 14, 0)),
    );

    expect(normalized, '因为宝宝哭了');
    final intent = parser.parse(normalized);
    expect(intent.intentType, VoiceIntentType.unknown);
  });
}
