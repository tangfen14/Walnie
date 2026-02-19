import 'dart:convert';

import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/infrastructure/repositories/api_event_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('list decodes events from remote API', () async {
    final client = MockClient((http.Request request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/v1/events');
      return http.Response(
        jsonEncode([
          {
            'id': 'event-1',
            'type': 'feed',
            'occurredAt': '2026-02-18T10:00:00.000Z',
            'feedMethod': 'bottleFormula',
            'durationMin': null,
            'amountMl': 60,
            'pumpStartAt': null,
            'pumpEndAt': null,
            'note': 'ok',
            'createdAt': '2026-02-18T10:00:00.000Z',
            'updatedAt': '2026-02-18T10:00:00.000Z',
          },
        ]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = ApiEventRepository(
      baseUrl: 'http://api.example.com',
      httpClient: client,
    );

    final result = await repository.list(
      DateTime.parse('2026-02-18T00:00:00.000Z'),
      DateTime.parse('2026-02-19T00:00:00.000Z'),
    );

    expect(result, hasLength(1));
    expect(result.first.type, EventType.feed);
    expect(result.first.amountMl, 60);
  });

  test('latest returns null when server responds 404', () async {
    final client = MockClient((http.Request request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/v1/events/latest');
      return http.Response('{"message":"not found"}', 404);
    });

    final repository = ApiEventRepository(
      baseUrl: 'http://api.example.com',
      httpClient: client,
    );

    final event = await repository.latest(EventType.feed);
    expect(event, isNull);
  });

  test('create throws when server fails', () async {
    final client = MockClient((_) async {
      return http.Response('{"message":"error"}', 500);
    });

    final repository = ApiEventRepository(
      baseUrl: 'http://api.example.com',
      httpClient: client,
    );

    final event = BabyEvent(
      id: 'event-2',
      type: EventType.pee,
      occurredAt: DateTime.parse('2026-02-18T10:01:00.000Z'),
      createdAt: DateTime.parse('2026-02-18T10:01:00.000Z'),
      updatedAt: DateTime.parse('2026-02-18T10:01:00.000Z'),
    );

    await expectLater(
      () => repository.create(event),
      throwsA(isA<ApiRepositoryException>()),
    );
  });

  test('delete sends request to remote API', () async {
    final client = MockClient((http.Request request) async {
      expect(request.method, 'DELETE');
      expect(request.url.path, '/v1/events/event-3');
      return http.Response('', 204);
    });

    final repository = ApiEventRepository(
      baseUrl: 'http://api.example.com',
      httpClient: client,
    );

    await repository.deleteById('event-3');
  });
}
