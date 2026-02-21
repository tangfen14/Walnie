import 'dart:async';
import 'dart:convert';

import 'package:baby_tracker/domain/entities/voice_normalization_config.dart';
import 'package:baby_tracker/infrastructure/voice/voice_normalization_config_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const cacheKey = 'voice_normalization_config_cache_v1';

  Map<String, dynamic> makeConfigJson({
    required String version,
    required DateTime updatedAt,
    required DateTime fetchedAt,
    int ttlSeconds = 3600,
  }) {
    return <String, dynamic>{
      'version': version,
      'ttlSeconds': ttlSeconds,
      'updatedAt': updatedAt.toIso8601String(),
      'fetchedAt': fetchedAt.toIso8601String(),
      'rules': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 'r1',
          'from': '为',
          'to': '喂',
          'scope': 'rule_only',
          'priority': 120,
          'contextKeywords': <String>['奶', 'ml'],
          'blockPhrases': <String>['因为', '认为'],
          'windowChars': 3,
        },
      ],
    };
  }

  test(
    'returns builtin fallback when no cache and no remote base url',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();

      final repository = VoiceNormalizationConfigRepositoryImpl(
        httpClient: MockClient((_) async {
          fail('no remote request expected');
        }),
        sharedPreferences: preferences,
        baseUrl: '',
        nowProvider: () => DateTime(2026, 2, 21, 14, 0),
      );

      final config = await repository.getActiveConfig();
      expect(config.version, 'builtin-v1');
      expect(config.rules, isNotEmpty);
    },
  );

  test('reads cache immediately before refresh', () async {
    final cached = makeConfigJson(
      version: 'cached-v1',
      updatedAt: DateTime(2026, 2, 21, 12, 0),
      fetchedAt: DateTime(2026, 2, 21, 13, 30),
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      cacheKey: jsonEncode(cached),
    });
    final preferences = await SharedPreferences.getInstance();

    final repository = VoiceNormalizationConfigRepositoryImpl(
      httpClient: MockClient((_) async {
        fail('should not refresh because cache is fresh');
      }),
      sharedPreferences: preferences,
      baseUrl: 'https://api.example.com',
      nowProvider: () => DateTime(2026, 2, 21, 14, 0),
    );

    final config = await repository.getActiveConfig();
    expect(config.version, 'cached-v1');
  });

  test('refreshes stale cache from remote and persists', () async {
    final stale = makeConfigJson(
      version: 'cached-v1',
      ttlSeconds: 60,
      updatedAt: DateTime(2026, 2, 21, 10, 0),
      fetchedAt: DateTime(2026, 2, 21, 10, 0),
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      cacheKey: jsonEncode(stale),
    });
    final preferences = await SharedPreferences.getInstance();

    var requestCount = 0;
    final client = MockClient((http.Request request) async {
      requestCount += 1;
      expect(
        request.url.toString(),
        'https://api.example.com/v1/voice/normalization-config',
      );
      return http.Response.bytes(
        utf8.encode(
          jsonEncode(
            makeConfigJson(
              version: 'remote-v2',
              ttlSeconds: 3600,
              updatedAt: DateTime(2026, 2, 21, 14, 0),
              fetchedAt: DateTime(2026, 2, 21, 14, 0),
            ),
          ),
        ),
        200,
        headers: <String, String>{
          'etag': 'W/"remote-v2"',
          'content-type': 'application/json; charset=utf-8',
        },
      );
    });

    final repository = VoiceNormalizationConfigRepositoryImpl(
      httpClient: client,
      sharedPreferences: preferences,
      baseUrl: 'https://api.example.com',
      nowProvider: () => DateTime(2026, 2, 21, 14, 5),
    );

    await repository.refreshIfStale();
    final active = await repository.getActiveConfig();

    expect(requestCount, 1);
    expect(active.version, 'remote-v2');
    expect(active.etag, 'W/"remote-v2"');

    final persisted = preferences.getString(cacheKey);
    expect(persisted, isNotNull);
    final persistedJson = jsonDecode(persisted!) as Map<String, dynamic>;
    expect(persistedJson['version'], 'remote-v2');
  });

  test('deduplicates in-flight refresh requests', () async {
    final stale = VoiceNormalizationConfig(
      version: 'stale-v1',
      ttlSeconds: 60,
      updatedAt: DateTime(2026, 2, 21, 10, 0),
      fetchedAt: DateTime(2026, 2, 21, 10, 0),
      rules: const <VoiceNormalizationRule>[],
    );
    SharedPreferences.setMockInitialValues(<String, Object>{
      cacheKey: jsonEncode(stale.toJson()),
    });
    final preferences = await SharedPreferences.getInstance();

    var requestCount = 0;
    final responseCompleter = Completer<http.Response>();
    final client = MockClient((_) {
      requestCount += 1;
      return responseCompleter.future;
    });
    final repository = VoiceNormalizationConfigRepositoryImpl(
      httpClient: client,
      sharedPreferences: preferences,
      baseUrl: 'https://api.example.com',
      nowProvider: () => DateTime(2026, 2, 21, 14, 5),
    );

    final first = repository.refreshIfStale();
    final second = repository.refreshIfStale();

    responseCompleter.complete(
      http.Response.bytes(
        utf8.encode(
          jsonEncode(
            makeConfigJson(
              version: 'remote-v3',
              ttlSeconds: 3600,
              updatedAt: DateTime(2026, 2, 21, 14, 6),
              fetchedAt: DateTime(2026, 2, 21, 14, 6),
            ),
          ),
        ),
        200,
        headers: <String, String>{
          'content-type': 'application/json; charset=utf-8',
        },
      ),
    );

    await Future.wait(<Future<void>>[first, second]);
    expect(requestCount, 1);
  });
}
