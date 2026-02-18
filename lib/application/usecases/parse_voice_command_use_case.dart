import 'package:baby_tracker/domain/entities/voice_intent.dart';
import 'package:baby_tracker/domain/services/voice_command_service.dart';

class ParseVoiceCommandUseCase {
  ParseVoiceCommandUseCase(this._voiceCommandService);

  final VoiceCommandService _voiceCommandService;

  Future<VoiceIntent> fromTranscript(
    String transcript, {
    VoiceParseProgressListener? onProgress,
  }) {
    return _voiceCommandService.parse(transcript, onProgress: onProgress);
  }

  Future<String> transcribe() {
    return _voiceCommandService.transcribe();
  }
}
