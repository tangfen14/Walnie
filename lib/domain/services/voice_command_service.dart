import 'package:baby_tracker/domain/entities/voice_intent.dart';

enum VoiceParseProgress {
  ruleMatching,
  ruleMatched,
  fallbackToLlm,
  llmMatched,
  unknown,
}

typedef VoiceParseProgressListener = void Function(VoiceParseProgress progress);

class VoiceParseCancellationToken {
  bool _isCancelled = false;
  final List<void Function()> _cancelCallbacks = <void Function()>[];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) {
      return;
    }
    _isCancelled = true;
    final callbacks = List<void Function()>.from(_cancelCallbacks);
    _cancelCallbacks.clear();
    for (final callback in callbacks) {
      callback();
    }
  }

  void onCancel(void Function() callback) {
    if (_isCancelled) {
      callback();
      return;
    }
    _cancelCallbacks.add(callback);
  }
}

class VoiceParseCancelledException implements Exception {
  const VoiceParseCancelledException();

  @override
  String toString() => 'voice parse cancelled';
}

abstract class VoiceCommandService {
  Future<String> transcribe();

  Future<VoiceIntent> parse(
    String transcript, {
    VoiceParseProgressListener? onProgress,
    VoiceParseCancellationToken? cancellationToken,
  });
}
