import 'dart:async';
import 'dart:convert';

import 'package:baby_tracker/domain/entities/voice_intent.dart';
import 'package:http/http.dart' as http;

class LlmFallbackParser {
  const LlmFallbackParser({http.Client? httpClient}) : _httpClient = httpClient;

  // 代码内默认配置：可直接改这里
  static const String _hardcodedEndpoint =
      'https://open.bigmodel.cn/api/paas/v4/chat/completions';
  static const String _hardcodedModel = 'glm-4';
  static const String _hardcodedApiKey =
      '866fa02611264f668e30f81d11425355.TpTYRsDzlUbqYAZC';
  static const int _hardcodedMaxInputWords = 40;
  static const int _hardcodedMaxTranscriptChars = 180;
  static const int _hardcodedMaxTokensPerWord = 2;
  static const int _hardcodedMaxTotalOutputTokens = 80;
  static const int _hardcodedMinOutputTokens = 24;
  static const int _hardcodedHttpTimeoutMs = 10000;
  static const double _hardcodedTemperature = 0.1;

  // 仍支持 --dart-define 覆盖（有值时优先生效）
  static const String _endpoint = String.fromEnvironment(
    'LLM_PARSER_ENDPOINT',
    defaultValue: _hardcodedEndpoint,
  );
  static const String _model = String.fromEnvironment(
    'LLM_PARSER_MODEL',
    defaultValue: _hardcodedModel,
  );
  static const String _apiKey = String.fromEnvironment(
    'LLM_PARSER_API_KEY',
    defaultValue: _hardcodedApiKey,
  );
  static const int _maxInputWords = int.fromEnvironment(
    'LLM_MAX_INPUT_WORDS',
    defaultValue: _hardcodedMaxInputWords,
  );
  static const int _maxTranscriptChars = int.fromEnvironment(
    'LLM_MAX_TRANSCRIPT_CHARS',
    defaultValue: _hardcodedMaxTranscriptChars,
  );
  static const int _maxTokensPerWord = int.fromEnvironment(
    'LLM_MAX_TOKENS_PER_WORD',
    defaultValue: _hardcodedMaxTokensPerWord,
  );
  static const int _maxTotalOutputTokens = int.fromEnvironment(
    'LLM_MAX_TOTAL_OUTPUT_TOKENS',
    defaultValue: _hardcodedMaxTotalOutputTokens,
  );
  static const int _minOutputTokens = int.fromEnvironment(
    'LLM_MIN_OUTPUT_TOKENS',
    defaultValue: _hardcodedMinOutputTokens,
  );
  static const int _httpTimeoutMs = int.fromEnvironment(
    'LLM_HTTP_TIMEOUT_MS',
    defaultValue: _hardcodedHttpTimeoutMs,
  );
  static double get _temperature {
    final tempStr = const String.fromEnvironment('LLM_TEMPERATURE');
    if (tempStr.isEmpty) {
      return _hardcodedTemperature;
    }
    return double.tryParse(tempStr) ?? _hardcodedTemperature;
  }

  final http.Client? _httpClient;

  Future<VoiceIntent?> parse(String transcript) async {
    if (_endpoint.isEmpty) {
      return null;
    }

    final rawTranscript = transcript.trim();
    if (rawTranscript.isEmpty) {
      return null;
    }

    final wordCount = _countWords(rawTranscript);
    if (wordCount > _maxInputWords) {
      return null;
    }

    final preparedTranscript = _truncate(rawTranscript, _maxTranscriptChars);
    final maxTokens = _computeMaxTokens(wordCount);

    final client = _httpClient ?? http.Client();
    final shouldCloseClient = _httpClient == null;

    try {
      final response = await client
          .post(
            Uri.parse(_endpoint),
            headers: <String, String>{
              'Content-Type': 'application/json',
              if (_apiKey.isNotEmpty) 'Authorization': 'Bearer $_apiKey',
            },
            body: jsonEncode(<String, dynamic>{
              'model': _model,
              'messages': <Map<String, String>>[
                {'role': 'system', 'content': _buildSystemPrompt()},
                {'role': 'user', 'content': preparedTranscript},
              ],
              'temperature': _temperature,
              'max_tokens': maxTokens,
            }),
          )
          .timeout(Duration(milliseconds: _httpTimeoutMs));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      // GLM-4 response format: choices[0].message.content
      final choices = decoded['choices'];
      if (choices is! List || choices.isEmpty) {
        return null;
      }

      final choice = choices[0];
      if (choice is! Map<String, dynamic>) {
        return null;
      }

      final message = choice['message'];
      if (message is! Map<String, dynamic>) {
        return null;
      }

      final content = message['content'];
      if (content is! String) {
        return null;
      }

      return _parseLlmResponse(content, rawTranscript);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  String _buildSystemPrompt() {
    return '''你是一个婴儿护理应用的语音意图识别助手。分析用户的语音转写文本，判断其意图类型并提取相关信息。

请严格按照以下 JSON 格式返回，不要包含任何其他文字：
{
  "intentType": "create_event | set_reminder | query_summary | unknown",
  "confidence": 0.0~1.0,
  "payload": {
    "eventType": "feed | poop | pee | diaper | pump",
    "occurredAt": "ISO8601 时间戳",
    "feedMethod": "breastLeft | breastRight | bottleFormula | bottleBreastmilk | mixed",
    "durationMin": 分钟数,
    "amountMl": 毫升数,
    "pumpStartAt": "吸奶开始时间(ISO8601)",
    "pumpEndAt": "吸奶结束时间(ISO8601)",
    "intervalHours": 提醒间隔小时数(1-6),
    "note": "备注"
  }
}

意图类型说明：
 - create_event: 记录婴儿事件（吃奶、便便、尿尿、换尿布、吸奶）
- set_reminder: 设置喂奶提醒间隔
- query_summary: 查询今日汇总、最近一次喂奶、下次提醒时间等
- unknown: 无法识别的意图

confidence 是识别置信度，0.0-1.0 之间，越接近 1.0 表示越确定。
payload 中只包含与 intentType 相关的字段，其他字段可以省略。''';
  }

  VoiceIntent _parseLlmResponse(String content, String rawTranscript) {
    try {
      // 尝试提取 JSON 内容（LLM 可能会在 JSON 前后添加解释性文字）
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      final jsonString = jsonMatch != null
          ? jsonMatch.group(0)!
          : content.trim();

      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return VoiceIntent.unknown(transcript: rawTranscript);
      }

      final intentTypeRaw =
          (decoded['intentType'] ?? decoded['intent'] ?? 'unknown')
              .toString()
              .toLowerCase();

      final payloadRaw = decoded['payload'];
      final payload = payloadRaw is Map<String, dynamic>
          ? payloadRaw
          : <String, dynamic>{};

      final confidence = (decoded['confidence'] is num)
          ? (decoded['confidence'] as num).toDouble()
          : 0.5;

      // 确保置信度在合理范围内
      final clampedConfidence = confidence.clamp(0.0, 1.0);

      return VoiceIntent(
        intentType: _mapIntent(intentTypeRaw),
        confidence: clampedConfidence,
        payload: payload,
        needsConfirmation: true,
        rawTranscript: rawTranscript,
      );
    } catch (_) {
      return VoiceIntent.unknown(transcript: rawTranscript);
    }
  }

  VoiceIntentType _mapIntent(String input) {
    switch (input) {
      case 'create_event':
      case 'createevent':
        return VoiceIntentType.createEvent;
      case 'set_reminder':
      case 'setreminder':
        return VoiceIntentType.setReminder;
      case 'query_summary':
      case 'querysummary':
        return VoiceIntentType.querySummary;
      default:
        return VoiceIntentType.unknown;
    }
  }

  int _countWords(String input) {
    final matches = RegExp(r'[A-Za-z0-9]+|[\u4E00-\u9FFF]').allMatches(input);
    return matches.length;
  }

  String _truncate(String input, int maxChars) {
    if (input.length <= maxChars) {
      return input;
    }
    return input.substring(0, maxChars);
  }

  int _computeMaxTokens(int wordCount) {
    final scaled = wordCount * _maxTokensPerWord;
    if (scaled < _minOutputTokens) {
      return _minOutputTokens;
    }
    if (scaled > _maxTotalOutputTokens) {
      return _maxTotalOutputTokens;
    }
    return scaled;
  }
}
