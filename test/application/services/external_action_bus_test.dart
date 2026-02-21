import 'package:baby_tracker/application/services/external_action_bus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExternalActionParser', () {
    test('parses quick voice feed from deep link uri', () {
      final action = ExternalActionParser.fromUri(
        Uri.parse('walnie://quick-add/voice-feed'),
      );

      expect(action, ExternalAction.quickVoiceFeed);
    });

    test('parses quick voice feed from notification action id', () {
      final action = ExternalActionParser.fromNotificationAction(
        actionId: ExternalActionParser.quickVoiceFeedActionId,
      );

      expect(action, ExternalAction.quickVoiceFeed);
    });

    test('parses quick voice feed from notification payload uri', () {
      final action = ExternalActionParser.fromNotificationAction(
        actionId: 'notification_tap',
        payload: ExternalActionParser.quickVoiceFeedDeepLink,
      );

      expect(action, ExternalAction.quickVoiceFeed);
    });
  });

  group('ExternalActionBus', () {
    test('stores action as pending without listeners', () {
      final bus = ExternalActionBus();
      addTearDown(bus.close);

      bus.dispatch(ExternalAction.quickVoiceFeed);

      final pending = bus.takePending();
      expect(pending, <ExternalAction>[ExternalAction.quickVoiceFeed]);
      expect(bus.takePending(), isEmpty);
    });

    test('dispatches directly when listener is active', () async {
      final bus = ExternalActionBus();
      addTearDown(bus.close);

      final future = bus.stream.first;
      bus.dispatch(ExternalAction.quickVoiceFeed);

      expect(await future, ExternalAction.quickVoiceFeed);
      expect(bus.takePending(), isEmpty);
    });
  });
}
