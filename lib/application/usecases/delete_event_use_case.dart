import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/repositories/event_repository.dart';
import 'package:baby_tracker/domain/services/reminder_service.dart';

class DeleteEventUseCase {
  DeleteEventUseCase({
    required EventRepository eventRepository,
    required ReminderService reminderService,
  }) : _eventRepository = eventRepository,
       _reminderService = reminderService;

  final EventRepository _eventRepository;
  final ReminderService _reminderService;

  Future<void> call(BabyEvent event) async {
    await _eventRepository.deleteById(event.id);

    if (event.type == EventType.feed) {
      await _reminderService.scheduleNextFromLatestFeed();
    }
  }
}
