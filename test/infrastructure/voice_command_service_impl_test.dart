import 'package:baby_tracker/domain/entities/voice_intent.dart';
import 'package:baby_tracker/domain/entities/voice_normalization_config.dart';
import 'package:baby_tracker/domain/repositories/voice_normalization_config_repository.dart';
import 'package:baby_tracker/domain/services/voice_command_service.dart';
import 'package:baby_tracker/infrastructure/voice/llm_fallback_parser.dart';
import 'package:baby_tracker/infrastructure/voice/rule_based_intent_parser.dart';
import 'package:baby_tracker/infrastructure/voice/voice_command_service_impl.dart';
import 'package:baby_tracker/infrastructure/voice/voice_text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  final defaultConfig = VoiceNormalizationConfig.fallback(
    now: DateTime(2026, 2, 21, 14, 0),
  );

  test(
    'uses normalized transcript for rule parser and keeps raw note',
    () async {
      final repository = _FakeVoiceNormalizationConfigRepository(defaultConfig);
      final normalizer = _FakeVoiceTextNormalizer(
        normalizedOutput: '1点45分喂奶50ml',
      );
      final llm = _FakeLlmFallbackParser(
        result: VoiceIntent.unknown(transcript: 'should-not-reach'),
      );

      final service = VoiceCommandServiceImpl(
        speechToText: SpeechToText(),
        ruleBasedIntentParser: RuleBasedIntentParser(
          nowProvider: () => DateTime(2026, 2, 21, 14, 5),
        ),
        llmFallbackParser: llm,
        voiceNormalizationConfigRepository: repository,
        voiceTextNormalizer: normalizer,
      );

      final intent = await service.parse('1点45分为奶50ml');

      expect(intent.intentType, VoiceIntentType.createEvent);
      expect(intent.payload['eventType'], 'feed');
      expect(intent.payload['note'], '1点45分为奶50ml');
      expect(llm.callCount, 0);
      expect(normalizer.lastRaw, '1点45分为奶50ml');
      expect(repository.getActiveCallCount, 1);
    },
  );

  test('keeps raw transcript for llm fallback input', () async {
    final repository = _FakeVoiceNormalizationConfigRepository(defaultConfig);
    final normalizer = _FakeVoiceTextNormalizer(normalizedOutput: '天气不错');
    final llm = _FakeLlmFallbackParser(
      result: VoiceIntent(
        intentType: VoiceIntentType.querySummary,
        confidence: 0.8,
        payload: const <String, dynamic>{'query': '因为宝宝哭了'},
        needsConfirmation: false,
        rawTranscript: '因为宝宝哭了',
      ),
    );

    final service = VoiceCommandServiceImpl(
      speechToText: SpeechToText(),
      ruleBasedIntentParser: RuleBasedIntentParser(
        nowProvider: () => DateTime(2026, 2, 21, 14, 5),
      ),
      llmFallbackParser: llm,
      voiceNormalizationConfigRepository: repository,
      voiceTextNormalizer: normalizer,
    );

    final intent = await service.parse('因为宝宝哭了');

    expect(intent.intentType, VoiceIntentType.querySummary);
    expect(llm.callCount, 1);
    expect(llm.lastTranscript, '因为宝宝哭了');
  });
}

class _FakeVoiceNormalizationConfigRepository
    implements VoiceNormalizationConfigRepository {
  _FakeVoiceNormalizationConfigRepository(this._config);

  final VoiceNormalizationConfig _config;
  int getActiveCallCount = 0;
  int refreshCallCount = 0;

  @override
  Future<VoiceNormalizationConfig> getActiveConfig() async {
    getActiveCallCount += 1;
    return _config;
  }

  @override
  Future<void> refreshIfStale() async {
    refreshCallCount += 1;
  }
}

class _FakeVoiceTextNormalizer extends VoiceTextNormalizer {
  _FakeVoiceTextNormalizer({required this.normalizedOutput});

  final String normalizedOutput;
  String? lastRaw;

  @override
  String normalizeForRule(String raw, VoiceNormalizationConfig config) {
    lastRaw = raw;
    return normalizedOutput;
  }
}

class _FakeLlmFallbackParser extends LlmFallbackParser {
  _FakeLlmFallbackParser({required this.result});

  final VoiceIntent result;
  int callCount = 0;
  String? lastTranscript;

  @override
  Future<VoiceIntent?> parse(
    String transcript, {
    VoiceParseCancellationToken? cancellationToken,
  }) async {
    callCount += 1;
    lastTranscript = transcript;
    return result;
  }
}
