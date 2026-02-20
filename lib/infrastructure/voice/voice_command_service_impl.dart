import 'dart:async';

import 'package:baby_tracker/domain/entities/voice_intent.dart';
import 'package:baby_tracker/domain/services/voice_command_service.dart';
import 'package:baby_tracker/infrastructure/voice/llm_fallback_parser.dart';
import 'package:baby_tracker/infrastructure/voice/rule_based_intent_parser.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceCommandServiceImpl implements VoiceCommandService {
  VoiceCommandServiceImpl({
    required SpeechToText speechToText,
    required RuleBasedIntentParser ruleBasedIntentParser,
    required LlmFallbackParser llmFallbackParser,
  }) : _speechToText = speechToText,
       _ruleBasedIntentParser = ruleBasedIntentParser,
       _llmFallbackParser = llmFallbackParser;

  final SpeechToText _speechToText;
  final RuleBasedIntentParser _ruleBasedIntentParser;
  final LlmFallbackParser _llmFallbackParser;

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

    onProgress?.call(VoiceParseProgress.ruleMatching);
    final ruleIntent = _ruleBasedIntentParser.parse(transcript);

    if (cancellationToken?.isCancelled == true) {
      throw const VoiceParseCancelledException();
    }

    if (ruleIntent.intentType != VoiceIntentType.unknown) {
      onProgress?.call(VoiceParseProgress.ruleMatched);
      return ruleIntent;
    }

    onProgress?.call(VoiceParseProgress.fallbackToLlm);
    final llmIntent = await _llmFallbackParser.parse(
      transcript,
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
