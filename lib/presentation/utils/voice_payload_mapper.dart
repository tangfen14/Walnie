import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/voice_intent.dart';

BabyEvent eventFromVoiceIntent(VoiceIntent intent) {
  final payload = intent.payload;

  final eventTypeString = (payload['eventType'] as String? ?? 'feed').trim();
  EventType? eventType;
  for (final item in EventType.values) {
    if (item.name == eventTypeString) {
      eventType = item;
      break;
    }
  }

  final occurredAtRaw = payload['occurredAt'] as String?;
  final occurredAt = occurredAtRaw == null
      ? DateTime.now()
      : DateTime.tryParse(occurredAtRaw);

  final feedMethodRaw = payload['feedMethod'] as String?;
  FeedMethod? feedMethod;
  for (final item in FeedMethod.values) {
    if (item.name == feedMethodRaw) {
      feedMethod = item;
      break;
    }
  }

  final durationMin = _toInt(payload['durationMin']);
  final amountMl = _toInt(payload['amountMl']);
  final pumpStartAt = _toDateTime(payload['pumpStartAt']);
  final pumpEndAt = _toDateTime(payload['pumpEndAt']);

  return BabyEvent(
    type: eventType ?? EventType.feed,
    occurredAt: occurredAt ?? DateTime.now(),
    feedMethod: feedMethod,
    durationMin: durationMin,
    amountMl: amountMl,
    pumpStartAt: pumpStartAt,
    pumpEndAt: pumpEndAt,
    note: payload['note'] as String?,
  );
}

int? _toInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  return int.tryParse(value.toString());
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value.toString());
}
