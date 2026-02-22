import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class GlmAsrTranscriptionService {
  GlmAsrTranscriptionService({
    http.Client? httpClient,
    String? endpoint,
    String? model,
    String? apiKey,
    Duration? timeout,
  }) : _httpClient = httpClient ?? http.Client(),
       _endpoint = endpoint ?? _configuredEndpoint,
       _model = model ?? _configuredModel,
       _apiKey = apiKey ?? _configuredApiKey,
       _timeout = timeout ?? const Duration(seconds: 20),
       _ownsClient = httpClient == null;

  static const String _hardcodedEndpoint =
      'https://open.bigmodel.cn/api/paas/v4/audio/transcriptions';
  static const String _hardcodedModel = 'glm-asr-2512';
  static const String _hardcodedApiKey =
      '5af26d54284e43fab5819821da821275.QxCAYcBs1DHWT4wF';

  static const String _configuredEndpoint = String.fromEnvironment(
    'GLM_ASR_ENDPOINT',
    defaultValue: _hardcodedEndpoint,
  );
  static const String _configuredModel = String.fromEnvironment(
    'GLM_ASR_MODEL',
    defaultValue: _hardcodedModel,
  );
  static const String _configuredApiKey = String.fromEnvironment(
    'GLM_ASR_API_KEY',
    defaultValue: _hardcodedApiKey,
  );

  final http.Client _httpClient;
  final String _endpoint;
  final String _model;
  final String _apiKey;
  final Duration _timeout;
  final bool _ownsClient;

  Future<String?> transcribeFile(String filePath, {bool stream = false}) async {
    final normalizedPath = filePath.trim();
    if (normalizedPath.isEmpty || _apiKey.trim().isEmpty) {
      return null;
    }

    final file = File(normalizedPath);
    if (!await file.exists()) {
      return null;
    }

    final request = http.MultipartRequest('POST', Uri.parse(_endpoint));
    request.headers['Authorization'] = 'Bearer $_apiKey';
    request.fields['model'] = _model;
    request.fields['stream'] = stream ? 'true' : 'false';
    request.files.add(await http.MultipartFile.fromPath('file', normalizedPath));

    try {
      final streamedResponse = await _httpClient
          .send(request)
          .timeout(_timeout);
      if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
        return null;
      }

      final response = await http.Response.fromStream(streamedResponse);
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      return _extractText(decoded);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    if (_ownsClient) {
      _httpClient.close();
    }
  }

  String? _extractText(Map<String, dynamic> decoded) {
    final direct = decoded['text'];
    if (direct is String && direct.trim().isNotEmpty) {
      return direct.trim();
    }

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      final nested = data['text'];
      if (nested is String && nested.trim().isNotEmpty) {
        return nested.trim();
      }
    }

    final segments = decoded['segments'];
    if (segments is List) {
      final parts = <String>[];
      for (final segment in segments) {
        if (segment is Map<String, dynamic>) {
          final text = segment['text'];
          if (text is String && text.trim().isNotEmpty) {
            parts.add(text.trim());
          }
        }
      }
      if (parts.isNotEmpty) {
        return parts.join('');
      }
    }

    return null;
  }
}
