import 'package:baby_tracker/presentation/utils/relative_time_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 2, 21, 12, 0, 0);

  test('shows 刚刚 when within 3 minutes', () {
    final value = formatRelativeTime(
      DateTime(2026, 2, 21, 11, 57, 30),
      now: now,
    );

    expect(value, '刚刚');
  });

  test('shows minutes when over 3 minutes and below 1 hour', () {
    final value = formatRelativeTime(
      DateTime(2026, 2, 21, 11, 55, 0),
      now: now,
    );

    expect(value, '5分钟前');
  });

  test('shows hour and minute when 1 hour or more', () {
    final value = formatRelativeTime(DateTime(2026, 2, 21, 9, 40, 0), now: now);

    expect(value, '2小时20分钟前');
  });

  test('clamps future timestamps to 刚刚', () {
    final value = formatRelativeTime(DateTime(2026, 2, 21, 12, 8, 0), now: now);

    expect(value, '刚刚');
  });

  test('handles utc event time against local now by wall clock', () {
    final value = formatRelativeTime(
      DateTime.parse('2026-02-21T18:10:00.000Z'),
      now: DateTime(2026, 2, 21, 19, 5, 0),
    );

    expect(value, '55分钟前');
  });
}
