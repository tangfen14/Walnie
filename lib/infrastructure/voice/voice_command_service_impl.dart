import 'dart:async';

import 'package:baby_tracker/domain/entities/voice_intent.dart';
import 'package:baby_tracker/domain/repositories/voice_normalization_config_repository.dart';
import 'package:baby_tracker/domain/services/voice_command_service.dart';
import 'package:baby_tracker/infrastructure/voice/llm_fallback_parser.dart';
import 'package:baby_tracker/infrastructure/voice/rule_based_intent_parser.dart';
import 'package:baby_tracker/infrastructure/voice/voice_text_normalizer.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceCommandServiceImpl implements VoiceCommandService {
  VoiceCommandServiceImpl({
    required SpeechToText speechToText,
    required RuleBasedIntentParser ruleBasedIntentParser,
    required LlmFallbackParser llmFallbackParser,
    required VoiceNormalizationConfigRepository
    voiceNormalizationConfigRepository,
    required VoiceTextNormalizer voiceTextNormalizer,
  }) : _speechToText = speechToText,
       _ruleBasedIntentParser = ruleBasedIntentParser,
       _llmFallbackParser = llmFallbackParser,
       _voiceNormalizationConfigRepository = voiceNormalizationConfigRepository,
       _voiceTextNormalizer = voiceTextNormalizer;

  final SpeechToText _speechToText;
  final RuleBasedIntentParser _ruleBasedIntentParser;
  final LlmFallbackParser _llmFallbackParser;
  final VoiceNormalizationConfigRepository _voiceNormalizationConfigRepository;
  final VoiceTextNormalizer _voiceTextNormalizer;

  @override
  Future<String> transcribe() async {
    final initialized = await _speechToText.initialize();
    if (!initialized) {
      throw const VoiceTranscribeException('语音识别不可用，请检查系统权限');
    }

    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    final completer = Completer<String>();
    var transcript = '';

    await _speechToText.listen(
      localeId: 'zh_CN',
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 10),
      listenOptions: SpeechListenOptions(partialResults: true),
      onResult: (result) {
        transcript = result.recognizedWords.trim();
        if (result.finalResult && !completer.isCompleted) {
          completer.complete(transcript);
        }
      },
    );

    Timer(const Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        completer.complete(transcript);
      }
    });

    final output = await completer.future;
    await _speechToText.stop();

    if (output.isEmpty) {
      throw const VoiceTranscribeException('没有识别到有效语音，请再试一次');
    }

    return output;
  }

  @override
  Future<VoiceIntent> parse(
    String transcript, {
    VoiceParseProgressListener? onProgress,
    VoiceParseCancellationToken? cancellationToken,
  }) async {
    if (cancellationToken?.isCancelled == true) {
      throw const VoiceParseCancelledException();
    }

    final rawTranscript = transcript.trim();
    var normalizedForRule = rawTranscript;
    try {
      final normalizationConfig = await _voiceNormalizationConfigRepository
          .getActiveConfig();
      normalizedForRule = _voiceTextNormalizer.normalizeForRule(
        rawTranscript,
        normalizationConfig,
      );
      unawaited(_voiceNormalizationConfigRepository.refreshIfStale());
    } catch (_) {
      normalizedForRule = rawTranscript;
    }

    onProgress?.call(VoiceParseProgress.ruleMatching);
    final ruleIntent = _ruleBasedIntentParser.parse(normalizedForRule);

    if (cancellationToken?.isCancelled == true) {
      throw const VoiceParseCancelledException();
    }

    if (ruleIntent.intentType != VoiceIntentType.unknown) {
      onProgress?.call(VoiceParseProgress.ruleMatched);
      final mergedPayload = Map<String, dynamic>.from(ruleIntent.payload);
      mergedPayload['note'] = rawTranscript;
      return VoiceIntent(
        intentType: ruleIntent.intentType,
        confidence: ruleIntent.confidence,
        payload: mergedPayload,
        needsConfirmation: ruleIntent.needsConfirmation,
        rawTranscript: transcript,
      );
    }

    onProgress?.call(VoiceParseProgress.fallbackToLlm);
    final llmIntent = await _llmFallbackParser.parse(
      rawTranscript,
      cancellationToken: cancellationToken,
    );
    if (cancellationToken?.isCancelled == true) {
      throw const VoiceParseCancelledException();
    }

    if (llmIntent != null && llmIntent.intentType != VoiceIntentType.unknown) {
      onProgress?.call(VoiceParseProgress.llmMatched);
      return llmIntent;
    }

    if (cancellationToken?.isCancelled == true) {
      throw const VoiceParseCancelledException();
    }
    onProgress?.call(VoiceParseProgress.unknown);
    return VoiceIntent.unknown(transcript: transcript);
  }
}

class VoiceTranscribeException implements Exception {
  const VoiceTranscribeException(this.message);

  final String message;

  @override
  String toString() => message;
}
