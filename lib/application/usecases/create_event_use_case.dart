import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/repositories/event_repository.dart';
import 'package:baby_tracker/domain/services/reminder_service.dart';

class CreateEventUseCase {
  CreateEventUseCase({
    required EventRepository eventRepository,
    required ReminderService reminderService,
  }) : _eventRepository = eventRepository,
       _reminderService = reminderService;

  final EventRepository _eventRepository;
  final ReminderService _reminderService;

  Future<void> call(BabyEvent event) async {
    event.validateForSave();

    final now = DateTime.now();
    final toSave = event.copyWith(updatedAt: now, createdAt: event.createdAt);

    await _eventRepository.create(toSave);

    if (event.type == EventType.feed) {
      await _reminderService.scheduleNextFromLatestFeed();
    }
  }
}
