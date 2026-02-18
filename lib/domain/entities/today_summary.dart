class TodaySummary {
  const TodaySummary({
    required this.feedCount,
    required this.poopCount,
    required this.peeCount,
    required this.diaperCount,
    required this.pumpCount,
    this.latestFeedAt,
  });

  final int feedCount;
  final int poopCount;
  final int peeCount;
  final int diaperCount;
  final int pumpCount;
  final DateTime? latestFeedAt;

  TodaySummary copyWith({
    int? feedCount,
    int? poopCount,
    int? peeCount,
    int? diaperCount,
    int? pumpCount,
    DateTime? latestFeedAt,
    bool clearLatestFeedAt = false,
  }) {
    return TodaySummary(
      feedCount: feedCount ?? this.feedCount,
      poopCount: poopCount ?? this.poopCount,
      peeCount: peeCount ?? this.peeCount,
      diaperCount: diaperCount ?? this.diaperCount,
      pumpCount: pumpCount ?? this.pumpCount,
      latestFeedAt: clearLatestFeedAt
          ? null
          : (latestFeedAt ?? this.latestFeedAt),
    );
  }
}
