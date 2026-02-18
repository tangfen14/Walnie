import 'package:baby_tracker/domain/entities/voice_intent.dart';

enum VoiceParseProgress {
  ruleMatching,
  ruleMatched,
  fallbackToLlm,
  llmMatched,
  unknown,
}

typedef VoiceParseProgressListener = void Function(VoiceParseProgress progress);

abstract class VoiceCommandService {
  Future<String> transcribe();

  Future<VoiceIntent> parse(
    String transcript, {
    VoiceParseProgressListener? onProgress,
  });
}
