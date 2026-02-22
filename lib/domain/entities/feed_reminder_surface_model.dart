import 'package:baby_tracker/domain/entities/baby_event.dart';

class FeedReminderSurfaceModel {
  const FeedReminderSurfaceModel({
    required this.lastFeedAt,
    required this.nextReminderAt,
    required this.feedMethod,
    required this.feedAmountMl,
    required this.quickActionDeepLink,
  });

  final DateTime lastFeedAt;
  final DateTime? nextReminderAt;
  final FeedMethod feedMethod;
  final int? feedAmountMl;
  final String quickActionDeepLink;
}
