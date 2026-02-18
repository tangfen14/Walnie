import 'dart:convert';

import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/repositories/event_repository.dart';
import 'package:http/http.dart' as http;

class ApiEventRepository implements EventRepository {
  ApiEventRepository({required String baseUrl, required http.Client httpClient})
    : _baseUri = _parseBaseUri(baseUrl),
      _httpClient = httpClient;

  final Uri _baseUri;
  final http.Client _httpClient;

  @override
  Future<void> create(BabyEvent event) async {
    final response = await _httpClient.post(
      _buildUri('/v1/events'),
      headers: _jsonHeaders,
      body: jsonEncode(event.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    throw ApiRepositoryException(
      '创建事件失败',
      statusCode: response.statusCode,
      responseBody: response.body,
    );
  }

  @override
  Future<List<BabyEvent>> list(DateTime from, DateTime to) async {
    final response = await _httpClient.get(
      _buildUri('/v1/events', <String, String>{
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      }),
      headers: _jsonHeaders,
    );

    if (response.statusCode != 200) {
      throw ApiRepositoryException(
        '查询事件失败',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! List) {
      throw const ApiRepositoryException('服务端返回了非法事件列表');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(BabyEvent.fromJson)
        .toList(growable: false);
  }

  @override
  Future<BabyEvent?> latest(EventType type) async {
    final response = await _httpClient.get(
      _buildUri('/v1/events/latest', <String, String>{'type': type.name}),
      headers: _jsonHeaders,
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      throw ApiRepositoryException(
        '查询最新事件失败',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiRepositoryException('服务端返回了非法事件对象');
    }

    return BabyEvent.fromJson(decoded);
  }

  Uri _buildUri(String path, [Map<String, String>? query]) {
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;

    final normalizedPath = path.startsWith('/') ? path : '/$path';

    return _baseUri.replace(
      path: '$basePath$normalizedPath',
      queryParameters: query,
    );
  }

  static Uri _parseBaseUri(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      throw const ApiRepositoryException('EVENT_API_BASE_URL 不能为空');
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      throw ApiRepositoryException('非法 API 地址: $rawUrl');
    }

    return uri;
  }

  static const Map<String, String> _jsonHeaders = <String, String>{
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

class ApiRepositoryException implements Exception {
  const ApiRepositoryException(
    this.message, {
    this.statusCode,
    this.responseBody,
  });

  final String message;
  final int? statusCode;
  final String? responseBody;

  @override
  String toString() {
    final code = statusCode == null ? '' : ' (HTTP $statusCode)';
    return '$message$code${responseBody == null ? '' : ': $responseBody'}';
  }
}
