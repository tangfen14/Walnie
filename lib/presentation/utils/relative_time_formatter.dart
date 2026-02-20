String formatRelativeTime(DateTime time, {DateTime? now}) {
  final baseline = now ?? DateTime.now();
  final baselineWallClock = _toWallClock(baseline);
  final timeWallClock = _toWallClock(time);
  var diff = baselineWallClock.difference(timeWallClock);
  if (diff.isNegative) {
    diff = Duration.zero;
  }

  if (diff.inMinutes <= 3) {
    return '刚刚';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes}分钟前';
  }

  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;
  return '$hours小时$minutes分钟前';
}

DateTime _toWallClock(DateTime value) {
  return DateTime(
    value.year,
    value.month,
    value.day,
    value.hour,
    value.minute,
    value.second,
    value.millisecond,
    value.microsecond,
  );
}
