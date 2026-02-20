import 'package:uuid/uuid.dart';

enum EventType { feed, poop, pee, diaper, pump }

enum FeedMethod {
  breastLeft,
  breastRight,
  bottleFormula,
  bottleBreastmilk,
  mixed,
}

extension EventTypeX on EventType {
  String get labelZh {
    switch (this) {
      case EventType.feed:
        return '吃奶';
      case EventType.poop:
        return '便便';
      case EventType.pee:
        return '尿尿';
      case EventType.diaper:
        return '换尿布';
      case EventType.pump:
        return '吸奶';
    }
  }

  static EventType fromDb(String value) {
    return EventType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => EventType.feed,
    );
  }
}

extension FeedMethodX on FeedMethod {
  String get labelZh {
    switch (this) {
      case FeedMethod.breastLeft:
        return '亲喂（左侧）';
      case FeedMethod.breastRight:
        return '亲喂（右侧）';
      case FeedMethod.bottleFormula:
        return '奶粉喂养';
      case FeedMethod.bottleBreastmilk:
        return '瓶喂母乳';
      case FeedMethod.mixed:
        return '混合喂养';
    }
  }

  static FeedMethod? tryFromDb(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final method in FeedMethod.values) {
      if (method.name == value) {
        return method;
      }
    }
    return null;
  }
}

class BabyEvent {
  BabyEvent({
    String? id,
    required this.type,
    required this.occurredAt,
    this.feedMethod,
    this.durationMin,
    this.amountMl,
    this.pumpStartAt,
    this.pumpEndAt,
    this.note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final EventType type;
  final DateTime occurredAt;
  final FeedMethod? feedMethod;
  final int? durationMin;
  final int? amountMl;
  final DateTime? pumpStartAt;
  final DateTime? pumpEndAt;
  final String? note;
  final DateTime createdAt;
  final DateTime updatedAt;

  BabyEvent copyWith({
    String? id,
    EventType? type,
    DateTime? occurredAt,
    FeedMethod? feedMethod,
    int? durationMin,
    int? amountMl,
    DateTime? pumpStartAt,
    DateTime? pumpEndAt,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearFeedMethod = false,
    bool clearDuration = false,
    bool clearAmount = false,
    bool clearPumpStartAt = false,
    bool clearPumpEndAt = false,
    bool clearNote = false,
  }) {
    return BabyEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      occurredAt: occurredAt ?? this.occurredAt,
      feedMethod: clearFeedMethod ? null : (feedMethod ?? this.feedMethod),
      durationMin: clearDuration ? null : (durationMin ?? this.durationMin),
      amountMl: clearAmount ? null : (amountMl ?? this.amountMl),
      pumpStartAt: clearPumpStartAt ? null : (pumpStartAt ?? this.pumpStartAt),
      pumpEndAt: clearPumpEndAt ? null : (pumpEndAt ?? this.pumpEndAt),
      note: clearNote ? null : (note ?? this.note),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  void validateForSave() {
    if (type == EventType.feed) {
      if (feedMethod == null) {
        throw const FormatException('吃奶记录需要选择喂养方式');
      }
      final hasDuration = (durationMin ?? 0) > 0;
      final hasAmount = (amountMl ?? 0) > 0;
      if (!hasDuration && !hasAmount) {
        throw const FormatException('吃奶记录需要填写时长或毫升数');
      }
    }

    if (type == EventType.pump) {
      if (pumpStartAt == null || pumpEndAt == null) {
        throw const FormatException('吸奶记录需要填写开始和结束时间');
      }
      if (!pumpEndAt!.isAfter(pumpStartAt!)) {
        throw const FormatException('吸奶结束时间必须晚于开始时间');
      }
      if ((amountMl ?? 0) <= 0) {
        throw const FormatException('吸奶记录需要填写奶量(ml)');
      }
    }

    if (durationMin != null && durationMin! < 0) {
      throw const FormatException('时长不能小于 0');
    }

    if (amountMl != null && amountMl! <= 0) {
      throw const FormatException('毫升数必须大于 0');
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'occurredAt': occurredAt.toIso8601String(),
      'feedMethod': feedMethod?.name,
      'durationMin': durationMin,
      'amountMl': amountMl,
      'pumpStartAt': pumpStartAt?.toIso8601String(),
      'pumpEndAt': pumpEndAt?.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BabyEvent.fromJson(Map<String, dynamic> json) {
    return BabyEvent(
      id: json['id'] as String,
      type: EventTypeX.fromDb(json['type'] as String),
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      feedMethod: FeedMethodX.tryFromDb(json['feedMethod'] as String?),
      durationMin: json['durationMin'] as int?,
      amountMl: json['amountMl'] as int?,
      pumpStartAt: json['pumpStartAt'] == null
          ? null
          : DateTime.parse(json['pumpStartAt'] as String),
      pumpEndAt: json['pumpEndAt'] == null
          ? null
          : DateTime.parse(json['pumpEndAt'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
