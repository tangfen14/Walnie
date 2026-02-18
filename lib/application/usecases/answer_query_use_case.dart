import 'package:baby_tracker/application/usecases/get_today_summary_use_case.dart';
import 'package:baby_tracker/domain/entities/voice_intent.dart';
import 'package:baby_tracker/domain/services/reminder_service.dart';
import 'package:intl/intl.dart';

class AnswerQueryUseCase {
  AnswerQueryUseCase({
    required GetTodaySummaryUseCase getTodaySummaryUseCase,
    required ReminderService reminderService,
  }) : _getTodaySummaryUseCase = getTodaySummaryUseCase,
       _reminderService = reminderService;

  final GetTodaySummaryUseCase _getTodaySummaryUseCase;
  final ReminderService _reminderService;

  Future<String> call(VoiceIntent intent) async {
    final summary = await _getTodaySummaryUseCase();
    final query = (intent.payload['query'] as String? ?? '').trim();

    if (query.contains('最近') && query.contains('喂')) {
      if (summary.latestFeedAt == null) {
        return '今天还没有喂奶记录。';
      }
      return '最近一次喂奶：${DateFormat('HH:mm').format(summary.latestFeedAt!)}';
    }

    if (query.contains('下次') || query.contains('提醒')) {
      final nextTrigger = await _reminderService.nextTriggerTime();
      if (nextTrigger == null) {
        return '当前没有可用提醒，请先记录一次喂奶。';
      }
      return '下次喂奶提醒：${DateFormat('MM-dd HH:mm').format(nextTrigger)}';
    }

    return '今天喂奶 ${summary.feedCount} 次，吸奶 ${summary.pumpCount} 次，便便 ${summary.poopCount} 次，尿尿 ${summary.peeCount} 次。';
  }
}
