import 'package:baby_tracker/domain/entities/baby_event.dart';

abstract class EventRepository {
  Future<void> create(BabyEvent event);

  Future<List<BabyEvent>> list(DateTime from, DateTime to);

  Future<BabyEvent?> latest(EventType type);

  Future<void> deleteById(String id);
}
