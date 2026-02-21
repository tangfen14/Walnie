import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/voice_intent.dart';

class RuleBasedIntentParser {
  RuleBasedIntentParser({DateTime Function()? nowProvider})
    : _nowProvider = nowProvider ?? DateTime.now;

  final DateTime Function() _nowProvider;

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
    final diaperStatus = _extractDiaperStatus(text, eventType);

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
    if (eventType == EventType.diaper && diaperStatus != null) {
      payload['diaperStatus'] = diaperStatus.name;
      payload['changedDiaper'] = true;
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
    if (_containsAny(text, const ['换尿布', '尿布', '换片', '纸尿裤', '换纸尿裤'])) {
      return EventType.diaper;
    }

    if (_containsAny(text, const ['便便', '拉屎', '大便', '尿尿', '撒尿', '小便'])) {
      return EventType.diaper;
    }

    if (_containsAny(text, const ['吸奶', '吸乳', '吸出来'])) {
      return EventType.pump;
    }

    final hasFeedContext = _containsAny(text, const ['奶', '母乳', '配方奶', '奶瓶']);
    if (_containsAny(text, const ['喝水', '吃药', '喂药', '喝药']) && !hasFeedContext) {
      return null;
    }

    if (_containsAny(text, const [
      '喂奶',
      '吃奶',
      '喝奶',
      '母乳',
      '配方奶',
      '奶瓶',
      '炫',
      '吃',
      '喂',
      '喝',
      '顿顿顿',
      '喂养',
    ])) {
      return EventType.feed;
    }

    return null;
  }

  DiaperStatus? _extractDiaperStatus(String text, EventType eventType) {
    if (eventType != EventType.diaper) {
      return null;
    }

    final hasPoop = _containsAny(text, const ['便便', '拉屎', '大便']);
    final hasPee = _containsAny(text, const ['尿尿', '撒尿', '小便']);
    if (hasPoop && hasPee) {
      return DiaperStatus.mixed;
    }
    if (hasPoop) {
      return DiaperStatus.poop;
    }
    if (hasPee) {
      return DiaperStatus.pee;
    }
    return DiaperStatus.mixed;
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
    final now = _nowProvider();

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

    final monthDayClock = RegExp(
      r'(?<!\d)(\d{1,2})月(\d{1,2})日?\s*(?:(凌晨|早上|上午|中午|下午|傍晚|晚上|夜里|半夜)\s*)?(\d{1,2})点(?:\s*(\d{1,2})分?)?',
    ).firstMatch(text);
    if (monthDayClock != null) {
      final parsed = _buildDateTime(
        now: now,
        monthText: monthDayClock.group(1),
        dayText: monthDayClock.group(2),
        meridiemText: monthDayClock.group(3),
        hourText: monthDayClock.group(4),
        minuteText: monthDayClock.group(5),
      );
      if (parsed != null) {
        return parsed;
      }
    }

    final monthDayColonClock = RegExp(
      r'(?<!\d)(\d{1,2})月(\d{1,2})日?\s*(?:(凌晨|早上|上午|中午|下午|傍晚|晚上|夜里|半夜)\s*)?(\d{1,2})\s*[:：]\s*(\d{1,2})(?:\s*[:：]\s*\d{1,2})?(?!\d)',
    ).firstMatch(text);
    if (monthDayColonClock != null) {
      final parsed = _buildDateTime(
        now: now,
        monthText: monthDayColonClock.group(1),
        dayText: monthDayColonClock.group(2),
        meridiemText: monthDayColonClock.group(3),
        hourText: monthDayColonClock.group(4),
        minuteText: monthDayColonClock.group(5),
      );
      if (parsed != null) {
        return parsed;
      }
    }

    final clock = RegExp(
      r'(?:(凌晨|早上|上午|中午|下午|傍晚|晚上|夜里|半夜)\s*)?(?<!\d)(\d{1,2})点(?:\s*(\d{1,2})分?)?',
    ).firstMatch(text);
    if (clock != null) {
      final parsed = _buildDateTime(
        now: now,
        meridiemText: clock.group(1),
        hourText: clock.group(2),
        minuteText: clock.group(3),
      );
      if (parsed != null) {
        return parsed;
      }
    }

    final colonClock = RegExp(
      r'(?:(凌晨|早上|上午|中午|下午|傍晚|晚上|夜里|半夜)\s*)?(?<!\d)(\d{1,2})\s*[:：]\s*(\d{1,2})(?:\s*[:：]\s*\d{1,2})?(?!\d)',
    ).firstMatch(text);
    if (colonClock != null) {
      final parsed = _buildDateTime(
        now: now,
        meridiemText: colonClock.group(1),
        hourText: colonClock.group(2),
        minuteText: colonClock.group(3),
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

  DateTime? _buildDateTime({
    required DateTime now,
    String? monthText,
    String? dayText,
    String? meridiemText,
    String? hourText,
    String? minuteText,
  }) {
    final month = int.tryParse(monthText ?? '') ?? now.month;
    final day = int.tryParse(dayText ?? '') ?? now.day;
    final hour = int.tryParse(hourText ?? '');
    final minute = int.tryParse(minuteText ?? '0') ?? 0;

    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    if (hour == null || hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return null;
    }

    final resolvedHour = _resolveHourByMeridiem(
      now: now,
      hour: hour,
      meridiemText: meridiemText,
    );
    if (resolvedHour == null) {
      return null;
    }

    final candidate = DateTime(now.year, month, day, resolvedHour, minute);
    if (candidate.year != now.year ||
        candidate.month != month ||
        candidate.day != day) {
      return null;
    }
    return candidate;
  }

  int? _resolveHourByMeridiem({
    required DateTime now,
    required int hour,
    String? meridiemText,
  }) {
    final meridiem = meridiemText?.trim() ?? '';
    if (hour > 12 || meridiem.isEmpty) {
      if (hour <= 12 && meridiem.isEmpty && now.hour >= 12 && hour < 12) {
        return hour + 12;
      }
      return hour;
    }

    if (_containsAny(meridiem, const ['凌晨', '早上', '上午', '夜里', '半夜'])) {
      return hour == 12 ? 0 : hour;
    }

    if (_containsAny(meridiem, const ['中午', '下午', '傍晚', '晚上'])) {
      return hour < 12 ? hour + 12 : hour;
    }

    return hour;
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
