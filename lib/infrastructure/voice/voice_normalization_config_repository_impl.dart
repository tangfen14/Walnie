import 'dart:async';
import 'dart:convert';

import 'package:baby_tracker/domain/entities/voice_normalization_config.dart';
import 'package:baby_tracker/domain/repositories/voice_normalization_config_repository.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VoiceNormalizationConfigRepositoryImpl
    implements VoiceNormalizationConfigRepository {
  VoiceNormalizationConfigRepositoryImpl({
    required http.Client httpClient,
    required SharedPreferences sharedPreferences,
    required String baseUrl,
    DateTime Function()? nowProvider,
  }) : _httpClient = httpClient,
       _sharedPreferences = sharedPreferences,
       _baseUri = _parseBaseUri(baseUrl),
       _nowProvider = nowProvider ?? DateTime.now;

  static const String _cacheKey = 'voice_normalization_config_cache_v1';
  static const Duration _requestTimeout = Duration(seconds: 5);

  final http.Client _httpClient;
  final SharedPreferences _sharedPreferences;
  final Uri? _baseUri;
  final DateTime Function() _nowProvider;

  VoiceNormalizationConfig? _memoryConfig;
  Future<void>? _inFlightRefresh;

  @override
  Future<VoiceNormalizationConfig> getActiveConfig() async {
    final config =
        _memoryConfig ??
        _readCache() ??
        VoiceNormalizationConfig.fallback(now: _nowProvider());
    _memoryConfig = config;
    return config;
  }

  @override
  Future<void> refreshIfStale() async {
    final baseline =
        _memoryConfig ??
        _readCache() ??
        VoiceNormalizationConfig.fallback(now: _nowProvider());
    _memoryConfig ??= baseline;

    if (!baseline.isStaleAt(_nowProvider())) {
      return;
    }

    await _refreshFromRemote(baseline);
  }

  Future<void> _refreshFromRemote(VoiceNormalizationConfig baseline) {
    final running = _inFlightRefresh;
    if (running != null) {
      return running;
    }

    late final Future<void> future;
    future = _fetchAndPersist(baseline).whenComplete(() {
      if (identical(_inFlightRefresh, future)) {
        _inFlightRefresh = null;
      }
    });
    _inFlightRefresh = future;
    return future;
  }

  Future<void> _fetchAndPersist(VoiceNormalizationConfig baseline) async {
    final endpoint = _buildConfigUri();
    if (endpoint == null) {
      _persist(
        baseline.copyWith(fetchedAt: _nowProvider(), etag: baseline.etag),
      );
      return;
    }

    final headers = <String, String>{'Accept': 'application/json'};
    final etag = baseline.etag?.trim();
    if (etag != null && etag.isNotEmpty) {
      headers['If-None-Match'] = etag;
    }

    http.Response response;
    try {
      response = await _httpClient
          .get(endpoint, headers: headers)
          .timeout(_requestTimeout);
    } catch (_) {
      return;
    }

    if (response.statusCode == 304) {
      _persist(
        baseline.copyWith(
          fetchedAt: _nowProvider(),
          etag: response.headers['etag'] ?? baseline.etag,
        ),
      );
      return;
    }

    if (response.statusCode != 200) {
      return;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    final parsed = VoiceNormalizationConfig.fromJson(
      decoded,
      etag: response.headers['etag'] ?? decoded['etag']?.toString(),
      fetchedAt: _nowProvider(),
    );
    _persist(parsed);
  }

  VoiceNormalizationConfig? _readCache() {
    final raw = _sharedPreferences.getString(_cacheKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return VoiceNormalizationConfig.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  void _persist(VoiceNormalizationConfig config) {
    _memoryConfig = config;
    final encoded = jsonEncode(config.toJson());
    unawaited(_sharedPreferences.setString(_cacheKey, encoded));
  }

  Uri? _buildConfigUri() {
    if (_baseUri == null) {
      return null;
    }

    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;
    return _baseUri.replace(path: '$basePath/v1/voice/normalization-config');
  }

  static Uri? _parseBaseUri(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return null;
    }
    return uri;
  }
}
