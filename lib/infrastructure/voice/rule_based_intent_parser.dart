import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/voice_intent.dart';

class RuleBasedIntentParser {
  VoiceIntent parse(String transcript) {
    final text = transcript.trim();
    if (text.isEmpty) {
      return VoiceIntent.unknown(transcript: transcript);
    }

    final reminderIntent = _parseReminder(text);
    if (reminderIntent != null) {
      return reminderIntent;
    }

    final queryIntent = _parseQuery(text);
    if (queryIntent != null) {
      return queryIntent;
    }

    final eventType = _detectEventType(text);
    if (eventType == null) {
      return VoiceIntent.unknown(transcript: transcript);
    }

    final occurredAt = _extractOccurredAt(text);
    final amountMl = _extractAmountMl(text);
    final durationMin = _extractDurationMin(text);
    final feedMethod = _extractFeedMethod(text, eventType);

    final payload = <String, dynamic>{
      'eventType': eventType.name,
      'occurredAt': occurredAt.toIso8601String(),
      'note': text,
    };

    if (feedMethod != null) {
      payload['feedMethod'] = feedMethod.name;
    }
    if (amountMl != null) {
      payload['amountMl'] = amountMl;
    }
    if (durationMin != null) {
      payload['durationMin'] = durationMin;
    }
    if (eventType == EventType.pump) {
      final startAt = occurredAt;
      final endAt = startAt.add(Duration(minutes: durationMin ?? 20));
      payload['pumpStartAt'] = startAt.toIso8601String();
      payload['pumpEndAt'] = endAt.toIso8601String();
    }

    final confidence = _computeConfidence(
      eventType: eventType,
      amountMl: amountMl,
      durationMin: durationMin,
      feedMethod: feedMethod,
    );

    return VoiceIntent(
      intentType: VoiceIntentType.createEvent,
      confidence: confidence,
      payload: payload,
      needsConfirmation: true,
      rawTranscript: transcript,
    );
  }

  VoiceIntent? _parseReminder(String text) {
    final normalized = text.replaceAll(' ', '');
    if (!normalized.contains('提醒')) {
      return null;
    }

    final hourMatch = RegExp(r'(\d+)\s*(?:小时|h|hr|Hr|H)').firstMatch(text);
    int? interval;

    if (hourMatch != null) {
      interval = int.tryParse(hourMatch.group(1)!);
    } else {
      final chineseHourMatch = RegExp(r'([一二三四五六])\s*小时').firstMatch(text);
      if (chineseHourMatch != null) {
        interval = _chineseDigit(chineseHourMatch.group(1)!);
      }
    }

    if (interval == null) {
      return VoiceIntent(
        intentType: VoiceIntentType.setReminder,
        confidence: 0.35,
        payload: <String, dynamic>{'intervalHours': 3},
        needsConfirmation: true,
        rawTranscript: text,
      );
    }

    final clamped = interval.clamp(1, 6);

    return VoiceIntent(
      intentType: VoiceIntentType.setReminder,
      confidence: 0.88,
      payload: <String, dynamic>{'intervalHours': clamped},
      needsConfirmation: true,
      rawTranscript: text,
    );
  }

  VoiceIntent? _parseQuery(String text) {
    if (!text.contains('今天') && !text.contains('最近') && !text.contains('下次')) {
      return null;
    }

    if (text.contains('几次') || text.contains('多少次') || text.contains('汇总')) {
      return VoiceIntent(
        intentType: VoiceIntentType.querySummary,
        confidence: 0.92,
        payload: <String, dynamic>{'query': text},
        needsConfirmation: false,
        rawTranscript: text,
      );
    }

    if (text.contains('最近') || text.contains('上次')) {
      return VoiceIntent(
        intentType: VoiceIntentType.querySummary,
        confidence: 0.9,
        payload: <String, dynamic>{'query': text},
        needsConfirmation: false,
        rawTranscript: text,
      );
    }

    if (text.contains('下次') || text.contains('提醒')) {
      return VoiceIntent(
        intentType: VoiceIntentType.querySummary,
        confidence: 0.86,
        payload: <String, dynamic>{'query': text},
        needsConfirmation: false,
        rawTranscript: text,
      );
    }

    return null;
  }

  EventType? _detectEventType(String text) {
    if (_containsAny(text, const ['便便', '拉屎', '大便'])) {
      return EventType.poop;
    }

    if (_containsAny(text, const ['尿尿', '撒尿', '小便'])) {
      return EventType.pee;
    }

    if (_containsAny(text, const ['吸奶', '吸乳', '吸出来'])) {
      return EventType.pump;
    }

    if (_containsAny(text, const ['喂奶', '吃奶', '喝奶', '母乳', '配方奶', '奶瓶'])) {
      return EventType.feed;
    }

    return null;
  }

  FeedMethod? _extractFeedMethod(String text, EventType eventType) {
    if (eventType != EventType.feed) {
      return null;
    }

    if (text.contains('混合')) {
      return FeedMethod.mixed;
    }

    if (text.contains('左') && _containsAny(text, const ['母乳', '亲喂'])) {
      return FeedMethod.breastLeft;
    }

    if (text.contains('右') && _containsAny(text, const ['母乳', '亲喂'])) {
      return FeedMethod.breastRight;
    }

    if (text.contains('奶瓶') && text.contains('母乳')) {
      return FeedMethod.bottleBreastmilk;
    }

    if (text.contains('奶瓶') || text.contains('配方奶')) {
      return FeedMethod.bottleFormula;
    }

    if (text.contains('母乳') || text.contains('亲喂')) {
      return FeedMethod.breastLeft;
    }

    return null;
  }

  DateTime _extractOccurredAt(String text) {
    final now = DateTime.now();

    final minutesAgo = RegExp(r'(\d+)\s*分钟前').firstMatch(text);
    if (minutesAgo != null) {
      final minutes = int.tryParse(minutesAgo.group(1)!);
      if (minutes != null) {
        return now.subtract(Duration(minutes: minutes));
      }
    }

    final hoursAgo = RegExp(r'(\d+)\s*小时前').firstMatch(text);
    if (hoursAgo != null) {
      final hours = int.tryParse(hoursAgo.group(1)!);
      if (hours != null) {
        return now.subtract(Duration(hours: hours));
      }
    }

    final todayClock = RegExp(
      r'今天\s*(\d{1,2})点(?:\s*(\d{1,2})分?)?',
    ).firstMatch(text);
    if (todayClock != null) {
      final parsed = _buildDateTime(
        now,
        todayClock.group(1),
        todayClock.group(2),
      );
      if (parsed != null) {
        return parsed;
      }
    }

    final todayColonClock = RegExp(
      r'今天\s*(\d{1,2})\s*[:：]\s*(\d{1,2})(?:\s*[:：]\s*\d{1,2})?',
    ).firstMatch(text);
    if (todayColonClock != null) {
      final parsed = _buildDateTime(
        now,
        todayColonClock.group(1),
        todayColonClock.group(2),
      );
      if (parsed != null) {
        return parsed;
      }
    }

    final clock = RegExp(
      r'(?<!\d)(\d{1,2})点(?:\s*(\d{1,2})分?)?',
    ).firstMatch(text);
    if (clock != null) {
      final parsed = _buildDateTime(now, clock.group(1), clock.group(2));
      if (parsed != null) {
        return parsed;
      }
    }

    final colonClock = RegExp(
      r'(?<!\d)(\d{1,2})\s*[:：]\s*(\d{1,2})(?:\s*[:：]\s*\d{1,2})?(?!\d)',
    ).firstMatch(text);
    if (colonClock != null) {
      final parsed = _buildDateTime(
        now,
        colonClock.group(1),
        colonClock.group(2),
      );
      if (parsed != null) {
        return parsed;
      }
    }

    if (text.contains('刚刚') || text.contains('刚才')) {
      return now;
    }

    return now;
  }

  DateTime? _buildDateTime(DateTime now, String? h, String? m) {
    final hour = int.tryParse(h ?? '');
    final minute = int.tryParse(m ?? '0') ?? 0;
    if (hour == null || hour > 23 || minute > 59) {
      return null;
    }

    final candidate = DateTime(now.year, now.month, now.day, hour, minute);
    if (candidate.isAfter(now.add(const Duration(minutes: 2)))) {
      return candidate.subtract(const Duration(days: 1));
    }

    return candidate;
  }

  int? _extractAmountMl(String text) {
    final match = RegExp(r'(\d{1,4})\s*(?:毫升|ml|ML)').firstMatch(text);
    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(1)!);
  }

  int? _extractDurationMin(String text) {
    final match = RegExp(r'(\d{1,3})\s*(?:分钟|分)').firstMatch(text);
    if (match == null) {
      return null;
    }

    return int.tryParse(match.group(1)!);
  }

  double _computeConfidence({
    required EventType eventType,
    required int? amountMl,
    required int? durationMin,
    required FeedMethod? feedMethod,
  }) {
    var score = 0.72;

    if (eventType == EventType.feed) {
      if (amountMl != null) {
        score += 0.08;
      }
      if (durationMin != null) {
        score += 0.08;
      }
      if (feedMethod != null) {
        score += 0.06;
      }
    } else {
      score += 0.1;
    }

    return score.clamp(0.0, 0.99);
  }

  int? _chineseDigit(String value) {
    switch (value) {
      case '一':
        return 1;
      case '二':
        return 2;
      case '三':
        return 3;
      case '四':
        return 4;
      case '五':
        return 5;
      case '六':
        return 6;
      default:
        return null;
    }
  }

  bool _containsAny(String source, List<String> words) {
    for (final word in words) {
      if (source.contains(word)) {
        return true;
      }
    }
    return false;
  }
}
