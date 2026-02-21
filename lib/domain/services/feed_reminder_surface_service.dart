import 'package:baby_tracker/domain/entities/feed_reminder_surface_model.dart';

abstract class FeedReminderSurfaceService {
  Future<void> initialize();

  Future<void> showOrUpdate(FeedReminderSurfaceModel model);

  Future<void> hide();
}
