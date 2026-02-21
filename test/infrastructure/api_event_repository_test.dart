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
    expect(result.first.eventMeta, isNull);
  });

  test('list decodes diaper event meta from remote API', () async {
    final client = MockClient((http.Request request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/v1/events');
      return http.Response(
        jsonEncode([
          {
            'id': 'event-diaper-1',
            'type': 'diaper',
            'occurredAt': '2026-02-20T11:00:00.000Z',
            'feedMethod': null,
            'durationMin': null,
            'amountMl': null,
            'pumpStartAt': null,
            'pumpEndAt': null,
            'note': 'test',
            'eventMeta': {
              'schemaVersion': 1,
              'status': 'mixed',
              'changedDiaper': true,
              'hasRash': false,
              'attachments': [
                {
                  'id': 'photo-1',
                  'mimeType': 'image/jpeg',
                  'base64': 'AAA',
                  'createdAt': '2026-02-20T11:00:00.000Z',
                },
              ],
            },
            'createdAt': '2026-02-20T11:00:00.000Z',
            'updatedAt': '2026-02-20T11:00:00.000Z',
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
      DateTime.parse('2026-02-20T00:00:00.000Z'),
      DateTime.parse('2026-02-21T00:00:00.000Z'),
    );

    expect(result, hasLength(1));
    expect(result.first.type, EventType.diaper);
    expect(result.first.eventMeta, isNotNull);
    expect(result.first.eventMeta!.status, DiaperStatus.mixed);
    expect(result.first.eventMeta!.changedDiaper, true);
    expect(result.first.eventMeta!.attachments, hasLength(1));
  });

  test('list decodes pump side ml from remote API eventMeta', () async {
    final client = MockClient((http.Request request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/v1/events');
      return http.Response(
        jsonEncode([
          {
            'id': 'event-pump-1',
            'type': 'pump',
            'occurredAt': '2026-02-20T10:00:00.000Z',
            'feedMethod': null,
            'durationMin': null,
            'amountMl': 75,
            'pumpStartAt': '2026-02-20T10:00:00.000Z',
            'pumpEndAt': '2026-02-20T10:20:00.000Z',
            'note': null,
            'eventMeta': {
              'schemaVersion': 1,
              'pumpLeftMl': 30,
              'pumpRightMl': 45,
              'attachments': [],
            },
            'createdAt': '2026-02-20T10:00:00.000Z',
            'updatedAt': '2026-02-20T10:00:00.000Z',
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
      DateTime.parse('2026-02-20T00:00:00.000Z'),
      DateTime.parse('2026-02-21T00:00:00.000Z'),
    );

    expect(result, hasLength(1));
    expect(result.first.type, EventType.pump);
    expect(result.first.amountMl, 75);
    expect(result.first.eventMeta?.pumpLeftMl, 30);
    expect(result.first.eventMeta?.pumpRightMl, 45);
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

  test('create serializes eventMeta to request body', () async {
    late Map<String, dynamic> requestBody;
    final client = MockClient((http.Request request) async {
      expect(request.method, 'POST');
      expect(request.url.path, '/v1/events');
      requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('{"id":"event-diaper-2"}', 201);
    });

    final repository = ApiEventRepository(
      baseUrl: 'http://api.example.com',
      httpClient: client,
    );

    final event = BabyEvent(
      id: 'event-diaper-2',
      type: EventType.diaper,
      occurredAt: DateTime.parse('2026-02-20T11:10:00.000Z'),
      note: 'meta test',
      createdAt: DateTime.parse('2026-02-20T11:10:00.000Z'),
      updatedAt: DateTime.parse('2026-02-20T11:10:00.000Z'),
      eventMeta: const EventMeta(
        schemaVersion: 1,
        status: DiaperStatus.pee,
        changedDiaper: false,
        hasRash: true,
        attachments: [
          EventAttachment(
            id: 'photo-2',
            mimeType: 'image/png',
            base64: 'BBB',
            createdAt: '2026-02-20T11:10:00.000Z',
          ),
        ],
      ),
    );

    await repository.create(event);
    final meta = requestBody['eventMeta'] as Map<String, dynamic>;
    expect(meta['status'], 'pee');
    expect(meta['changedDiaper'], false);
    expect(meta['hasRash'], true);
    expect((meta['attachments'] as List<dynamic>).length, 1);
  });

  test('create serializes pump left/right ml to request body', () async {
    late Map<String, dynamic> requestBody;
    final client = MockClient((http.Request request) async {
      requestBody = jsonDecode(request.body) as Map<String, dynamic>;
      return http.Response('{"id":"event-pump-2"}', 201);
    });

    final repository = ApiEventRepository(
      baseUrl: 'http://api.example.com',
      httpClient: client,
    );

    final start = DateTime.parse('2026-02-20T09:00:00.000Z');
    final event = BabyEvent(
      id: 'event-pump-2',
      type: EventType.pump,
      occurredAt: start,
      pumpStartAt: start,
      pumpEndAt: start.add(const Duration(minutes: 20)),
      amountMl: 80,
      eventMeta: const EventMeta(
        schemaVersion: 1,
        pumpLeftMl: 30,
        pumpRightMl: 50,
        attachments: [],
      ),
      createdAt: start,
      updatedAt: start,
    );

    await repository.create(event);

    final meta = requestBody['eventMeta'] as Map<String, dynamic>;
    expect(meta['pumpLeftMl'], 30);
    expect(meta['pumpRightMl'], 50);
  });
}
