import 'dart:async';

enum ExternalAction { quickVoiceFeed }

class ExternalActionBus {
  final StreamController<ExternalAction> _controller =
      StreamController<ExternalAction>.broadcast();
  final List<ExternalAction> _pending = <ExternalAction>[];

  Stream<ExternalAction> get stream => _controller.stream;

  void dispatch(ExternalAction action) {
    if (_controller.hasListener) {
      _controller.add(action);
      return;
    }
    _pending.add(action);
  }

  void dispatchUri(Uri uri) {
    final parsed = ExternalActionParser.fromUri(uri);
    if (parsed == null) {
      return;
    }
    dispatch(parsed);
  }

  List<ExternalAction> takePending() {
    final snapshot = List<ExternalAction>.of(_pending);
    _pending.clear();
    return snapshot;
  }

  void close() {
    _controller.close();
  }
}

class ExternalActionParser {
  static const String quickVoiceFeedActionId = 'quick_voice_feed';
  static const String quickVoiceFeedDeepLink = 'walnie://quick-add/voice-feed';

  static ExternalAction? fromUri(Uri uri) {
    final path = uri.path.toLowerCase();
    final host = uri.host.toLowerCase();
    final scheme = uri.scheme.toLowerCase();

    if (scheme != 'walnie') {
      return null;
    }

    if (host == 'quick-add' && path == '/voice-feed') {
      return ExternalAction.quickVoiceFeed;
    }

    return null;
  }

  static ExternalAction? fromNotificationAction({
    required String? actionId,
    String? payload,
  }) {
    if (actionId == quickVoiceFeedActionId) {
      return ExternalAction.quickVoiceFeed;
    }

    final parsed = Uri.tryParse(payload ?? '');
    if (parsed == null) {
      return null;
    }
    return fromUri(parsed);
  }
}
