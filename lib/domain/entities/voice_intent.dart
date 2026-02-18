enum VoiceIntentType { createEvent, setReminder, querySummary, unknown }

class VoiceIntent {
  const VoiceIntent({
    required this.intentType,
    required this.confidence,
    required this.payload,
    this.needsConfirmation = true,
    this.rawTranscript,
  });

  final VoiceIntentType intentType;
  final double confidence;
  final Map<String, dynamic> payload;
  final bool needsConfirmation;
  final String? rawTranscript;

  static VoiceIntent unknown({String? transcript}) {
    return VoiceIntent(
      intentType: VoiceIntentType.unknown,
      confidence: 0,
      payload: const <String, dynamic>{},
      needsConfirmation: true,
      rawTranscript: transcript,
    );
  }
}
