import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/repositories/event_repository.dart';

class GetTimelineUseCase {
  GetTimelineUseCase(this._eventRepository);
  final EventRepository _eventRepository;

  Future<List<BabyEvent>> call({int lookbackDays = 7, EventType? filterType}) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: lookbackDays));
    final allEvents = await _eventRepository.list(start, end);

    if (filterType == null) {
      return allEvents;
    }

    return allEvents.where((event) => event.type == filterType).toList();
  }
}
