class AppEnvironment {
  const AppEnvironment({
    required this.eventApiBaseUrl,
    this.voiceNormalizationApiBaseUrl = '',
  });

  const AppEnvironment.fromDartDefine()
    : eventApiBaseUrl = const String.fromEnvironment(
        'EVENT_API_BASE_URL',
        defaultValue: '',
      ),
      voiceNormalizationApiBaseUrl = const String.fromEnvironment(
        'VOICE_NORMALIZATION_API_BASE_URL',
        defaultValue: '',
      );

  final String eventApiBaseUrl;
  final String voiceNormalizationApiBaseUrl;

  bool get useRemoteBackend => normalizedEventApiBaseUrl.isNotEmpty;

  String get normalizedEventApiBaseUrl {
    final trimmed = eventApiBaseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  String get normalizedVoiceNormalizationApiBaseUrl {
    final trimmed = voiceNormalizationApiBaseUrl.trim();
    if (trimmed.isEmpty) {
      return normalizedEventApiBaseUrl;
    }
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
