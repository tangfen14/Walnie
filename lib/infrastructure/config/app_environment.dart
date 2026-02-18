class AppEnvironment {
  const AppEnvironment({required this.eventApiBaseUrl});

  const AppEnvironment.fromDartDefine()
    : eventApiBaseUrl = const String.fromEnvironment(
        'EVENT_API_BASE_URL',
        defaultValue: '',
      );

  final String eventApiBaseUrl;

  bool get useRemoteBackend => normalizedEventApiBaseUrl.isNotEmpty;

  String get normalizedEventApiBaseUrl {
    final trimmed = eventApiBaseUrl.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
