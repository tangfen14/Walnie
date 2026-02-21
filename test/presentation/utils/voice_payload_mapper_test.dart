import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/entities/voice_intent.dart';
import 'package:baby_tracker/presentation/utils/voice_payload_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'eventFromVoiceIntent defaults feed method to bottleBreastmilk for feed event',
    () {
      final intent = VoiceIntent(
        intentType: VoiceIntentType.createEvent,
        confidence: 0.9,
        payload: <String, dynamic>{
          'eventType': 'feed',
          'occurredAt': DateTime(2026, 2, 21, 9, 30).toIso8601String(),
          'amountMl': 60,
        },
        needsConfirmation: false,
        rawTranscript: '喂奶60毫升',
      );

      final event = eventFromVoiceIntent(intent);

      expect(event.type, EventType.feed);
      expect(event.feedMethod, FeedMethod.bottleBreastmilk);
      expect(event.amountMl, 60);
    },
  );
}
