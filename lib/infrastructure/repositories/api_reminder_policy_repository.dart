import 'dart:convert';

import 'package:baby_tracker/domain/entities/reminder_policy.dart';
import 'package:baby_tracker/domain/repositories/reminder_policy_repository.dart';
import 'package:baby_tracker/infrastructure/repositories/api_event_repository.dart';
import 'package:http/http.dart' as http;

class ApiReminderPolicyRepository implements ReminderPolicyRepository {
  ApiReminderPolicyRepository({
    required String baseUrl,
    required http.Client httpClient,
  }) : _baseUri = _parseBaseUri(baseUrl),
       _httpClient = httpClient;

  final Uri _baseUri;
  final http.Client _httpClient;

  @override
  Future<ReminderPolicy> getPolicy() async {
    final response = await _httpClient.get(
      _buildUri('/v1/reminder-policy'),
      headers: _jsonHeaders,
    );
    if (response.statusCode != 200) {
      throw ApiRepositoryException(
        '获取提醒策略失败',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
    return _decodePolicy(response.body);
  }

  @override
  Future<ReminderPolicy> upsertPolicy(ReminderPolicy policy) async {
    final response = await _httpClient.post(
      _buildUri('/v1/reminder-policy'),
      headers: _jsonHeaders,
      body: jsonEncode(<String, dynamic>{
        'intervalHours': policy.intervalHours,
      }),
    );
    if (response.statusCode != 200) {
      throw ApiRepositoryException(
        '更新提醒策略失败',
        statusCode: response.statusCode,
        responseBody: response.body,
      );
    }
    return _decodePolicy(response.body);
  }

  ReminderPolicy _decodePolicy(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiRepositoryException('服务端返回了非法提醒策略');
    }
    final intervalHours = decoded['intervalHours'];
    if (intervalHours is! int) {
      throw const ApiRepositoryException('服务端返回了非法提醒策略');
    }
    final policy = ReminderPolicy(intervalHours: intervalHours);
    policy.validate();
    return policy;
  }

  Uri _buildUri(String path) {
    final basePath = _baseUri.path.endsWith('/')
        ? _baseUri.path.substring(0, _baseUri.path.length - 1)
        : _baseUri.path;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return _baseUri.replace(path: '$basePath$normalizedPath');
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
