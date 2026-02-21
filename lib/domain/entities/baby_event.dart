import 'package:uuid/uuid.dart';

enum EventType { feed, poop, pee, diaper, pump }

enum DiaperStatus { poop, pee, mixed }

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
        return '喂奶';
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

extension DiaperStatusX on DiaperStatus {
  String get labelZh {
    switch (this) {
      case DiaperStatus.poop:
        return '臭臭';
      case DiaperStatus.pee:
        return '嘘嘘';
      case DiaperStatus.mixed:
        return '嘘嘘+臭臭';
    }
  }

  static DiaperStatus? tryFromDb(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final status in DiaperStatus.values) {
      if (status.name == value) {
        return status;
      }
    }
    return null;
  }
}

extension FeedMethodX on FeedMethod {
  String get labelZh {
    switch (this) {
      case FeedMethod.breastLeft:
        return '亲喂';
      case FeedMethod.breastRight:
        return '亲喂';
      case FeedMethod.bottleFormula:
        return '奶粉喂养';
      case FeedMethod.bottleBreastmilk:
        return '瓶装母乳';
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

class EventAttachment {
  const EventAttachment({
    required this.id,
    required this.mimeType,
    required this.base64,
    required this.createdAt,
  });

  final String id;
  final String mimeType;
  final String base64;
  final String createdAt;

  EventAttachment copyWith({
    String? id,
    String? mimeType,
    String? base64,
    String? createdAt,
  }) {
    return EventAttachment(
      id: id ?? this.id,
      mimeType: mimeType ?? this.mimeType,
      base64: base64 ?? this.base64,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'mimeType': mimeType,
      'base64': base64,
      'createdAt': createdAt,
    };
  }

  factory EventAttachment.fromJson(Map<String, dynamic> json) {
    return EventAttachment(
      id: (json['id'] as String?) ?? '',
      mimeType: (json['mimeType'] as String?) ?? '',
      base64: (json['base64'] as String?) ?? '',
      createdAt: (json['createdAt'] as String?) ?? '',
    );
  }
}

class EventMeta {
  const EventMeta({
    required this.schemaVersion,
    this.status,
    this.changedDiaper,
    this.hasRash,
    this.feedLeftDurationMin,
    this.feedRightDurationMin,
    this.pumpLeftMl,
    this.pumpRightMl,
    required this.attachments,
  });

  final int schemaVersion;
  final DiaperStatus? status;
  final bool? changedDiaper;
  final bool? hasRash;
  final int? feedLeftDurationMin;
  final int? feedRightDurationMin;
  final int? pumpLeftMl;
  final int? pumpRightMl;
  final List<EventAttachment> attachments;

  EventMeta copyWith({
    int? schemaVersion,
    DiaperStatus? status,
    bool? changedDiaper,
    bool? hasRash,
    int? feedLeftDurationMin,
    int? feedRightDurationMin,
    int? pumpLeftMl,
    int? pumpRightMl,
    List<EventAttachment>? attachments,
    bool clearStatus = false,
    bool clearChangedDiaper = false,
    bool clearHasRash = false,
    bool clearFeedLeftDuration = false,
    bool clearFeedRightDuration = false,
    bool clearPumpLeftMl = false,
    bool clearPumpRightMl = false,
  }) {
    return EventMeta(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      status: clearStatus ? null : (status ?? this.status),
      changedDiaper: clearChangedDiaper
          ? null
          : (changedDiaper ?? this.changedDiaper),
      hasRash: clearHasRash ? null : (hasRash ?? this.hasRash),
      feedLeftDurationMin: clearFeedLeftDuration
          ? null
          : (feedLeftDurationMin ?? this.feedLeftDurationMin),
      feedRightDurationMin: clearFeedRightDuration
          ? null
          : (feedRightDurationMin ?? this.feedRightDurationMin),
      pumpLeftMl: clearPumpLeftMl ? null : (pumpLeftMl ?? this.pumpLeftMl),
      pumpRightMl: clearPumpRightMl ? null : (pumpRightMl ?? this.pumpRightMl),
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'status': status?.name,
      'changedDiaper': changedDiaper,
      'hasRash': hasRash,
      'feedLeftDurationMin': feedLeftDurationMin,
      'feedRightDurationMin': feedRightDurationMin,
      'pumpLeftMl': pumpLeftMl,
      'pumpRightMl': pumpRightMl,
      'attachments': attachments.map((item) => item.toJson()).toList(),
    };
  }

  factory EventMeta.fromJson(Map<String, dynamic> json) {
    final rawAttachments = json['attachments'];
    final attachmentList = <EventAttachment>[];
    if (rawAttachments is List) {
      for (final item in rawAttachments) {
        if (item is Map<String, dynamic>) {
          attachmentList.add(EventAttachment.fromJson(item));
          continue;
        }
        if (item is Map) {
          attachmentList.add(
            EventAttachment.fromJson(item.cast<String, dynamic>()),
          );
        }
      }
    }

    final rawSchemaVersion = json['schemaVersion'];
    return EventMeta(
      schemaVersion: rawSchemaVersion is num ? rawSchemaVersion.toInt() : 1,
      status: DiaperStatusX.tryFromDb(json['status'] as String?),
      changedDiaper: json['changedDiaper'] as bool?,
      hasRash: json['hasRash'] as bool?,
      feedLeftDurationMin: _toNullableInt(json['feedLeftDurationMin']),
      feedRightDurationMin: _toNullableInt(json['feedRightDurationMin']),
      pumpLeftMl: _toNullableInt(json['pumpLeftMl']),
      pumpRightMl: _toNullableInt(json['pumpRightMl']),
      attachments: attachmentList,
    );
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
    EventMeta? eventMeta,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : eventMeta = _normalizeEventMeta(type, eventMeta),
       id = id ?? const Uuid().v4(),
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
  final EventMeta? eventMeta;
  final DateTime createdAt;
  final DateTime updatedAt;

  static EventMeta? _normalizeEventMeta(EventType type, EventMeta? eventMeta) {
    if (type == EventType.diaper) {
      if (eventMeta == null) {
        return const EventMeta(
          schemaVersion: 1,
          status: DiaperStatus.mixed,
          changedDiaper: true,
          hasRash: false,
          attachments: [],
        );
      }
      return eventMeta.copyWith(
        changedDiaper: eventMeta.changedDiaper ?? true,
        clearFeedLeftDuration: true,
        clearFeedRightDuration: true,
        clearPumpLeftMl: true,
        clearPumpRightMl: true,
        attachments: List<EventAttachment>.from(eventMeta.attachments),
      );
    }

    if (type == EventType.poop) {
      if (eventMeta == null) {
        return const EventMeta(
          schemaVersion: 1,
          status: DiaperStatus.poop,
          changedDiaper: true,
          attachments: [],
        );
      }
      return eventMeta.copyWith(
        status: eventMeta.status ?? DiaperStatus.poop,
        changedDiaper: eventMeta.changedDiaper ?? true,
        clearHasRash: true,
        clearFeedLeftDuration: true,
        clearFeedRightDuration: true,
        clearPumpLeftMl: true,
        clearPumpRightMl: true,
        attachments: List<EventAttachment>.from(eventMeta.attachments),
      );
    }

    if (type == EventType.pee) {
      if (eventMeta == null) {
        return const EventMeta(
          schemaVersion: 1,
          status: DiaperStatus.pee,
          changedDiaper: true,
          attachments: [],
        );
      }
      return eventMeta.copyWith(
        status: eventMeta.status ?? DiaperStatus.pee,
        changedDiaper: eventMeta.changedDiaper ?? true,
        clearHasRash: true,
        clearFeedLeftDuration: true,
        clearFeedRightDuration: true,
        clearPumpLeftMl: true,
        clearPumpRightMl: true,
        attachments: List<EventAttachment>.from(eventMeta.attachments),
      );
    }

    if (type == EventType.feed) {
      if (eventMeta == null) {
        return null;
      }
      return eventMeta.copyWith(
        clearStatus: true,
        clearChangedDiaper: true,
        clearHasRash: true,
        clearPumpLeftMl: true,
        clearPumpRightMl: true,
        attachments: const [],
      );
    }

    if (type == EventType.pump) {
      if (eventMeta == null) {
        return null;
      }
      return eventMeta.copyWith(
        clearStatus: true,
        clearChangedDiaper: true,
        clearHasRash: true,
        clearFeedLeftDuration: true,
        clearFeedRightDuration: true,
        attachments: const [],
      );
    }

    return null;
  }

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
    EventMeta? eventMeta,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearFeedMethod = false,
    bool clearDuration = false,
    bool clearAmount = false,
    bool clearPumpStartAt = false,
    bool clearPumpEndAt = false,
    bool clearNote = false,
    bool clearEventMeta = false,
  }) {
    final nextType = type ?? this.type;
    final resolvedEventMeta = clearEventMeta
        ? null
        : (eventMeta ?? this.eventMeta);

    return BabyEvent(
      id: id ?? this.id,
      type: nextType,
      occurredAt: occurredAt ?? this.occurredAt,
      feedMethod: clearFeedMethod ? null : (feedMethod ?? this.feedMethod),
      durationMin: clearDuration ? null : (durationMin ?? this.durationMin),
      amountMl: clearAmount ? null : (amountMl ?? this.amountMl),
      pumpStartAt: clearPumpStartAt ? null : (pumpStartAt ?? this.pumpStartAt),
      pumpEndAt: clearPumpEndAt ? null : (pumpEndAt ?? this.pumpEndAt),
      note: clearNote ? null : (note ?? this.note),
      eventMeta: resolvedEventMeta,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  void validateForSave() {
    if (type == EventType.feed) {
      if (feedMethod == null) {
        throw const FormatException('喂奶记录需要选择喂养方式');
      }
      final hasDuration = (durationMin ?? 0) > 0;
      final hasAmount = (amountMl ?? 0) > 0;
      final leftDuration = eventMeta?.feedLeftDurationMin;
      final rightDuration = eventMeta?.feedRightDurationMin;
      final hasSideDuration =
          (leftDuration ?? 0) > 0 || (rightDuration ?? 0) > 0;
      final hasBreastDuration = hasSideDuration || hasDuration;

      switch (feedMethod!) {
        case FeedMethod.breastLeft:
        case FeedMethod.breastRight:
          if (!hasBreastDuration) {
            throw const FormatException('亲喂记录需要填写左侧或右侧时长');
          }
          break;
        case FeedMethod.bottleFormula:
        case FeedMethod.bottleBreastmilk:
          if (!hasAmount) {
            throw const FormatException('瓶喂记录需要填写毫升数');
          }
          break;
        case FeedMethod.mixed:
          if (!hasBreastDuration && !hasAmount) {
            throw const FormatException('混合喂养需要填写左/右时长或瓶装毫升');
          }
          break;
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

    if (eventMeta?.feedLeftDurationMin != null &&
        eventMeta!.feedLeftDurationMin! < 0) {
      throw const FormatException('左侧时长不能小于 0');
    }

    if (eventMeta?.feedRightDurationMin != null &&
        eventMeta!.feedRightDurationMin! < 0) {
      throw const FormatException('右侧时长不能小于 0');
    }

    if (eventMeta?.pumpLeftMl != null && eventMeta!.pumpLeftMl! < 0) {
      throw const FormatException('左侧奶量不能小于 0');
    }

    if (eventMeta?.pumpRightMl != null && eventMeta!.pumpRightMl! < 0) {
      throw const FormatException('右侧奶量不能小于 0');
    }

    if (amountMl != null && amountMl! <= 0) {
      throw const FormatException('毫升数必须大于 0');
    }

    if (type == EventType.pump) {
      final leftMl = eventMeta?.pumpLeftMl;
      final rightMl = eventMeta?.pumpRightMl;
      if (leftMl != null || rightMl != null) {
        final sideTotal = (leftMl ?? 0) + (rightMl ?? 0);
        if (sideTotal <= 0) {
          throw const FormatException('吸奶记录需要填写左侧或右侧奶量');
        }
        if (amountMl != sideTotal) {
          throw const FormatException('吸奶总奶量需要等于左侧+右侧奶量');
        }
      }
    }

    if (type == EventType.diaper ||
        type == EventType.poop ||
        type == EventType.pee) {
      final meta = eventMeta;
      if (meta == null || meta.status == null) {
        throw const FormatException('尿布状态不能为空');
      }
      if (meta.changedDiaper == null) {
        throw const FormatException('请填写是否更换纸布');
      }
      if (meta.attachments.length > 3) {
        throw const FormatException('最多上传 3 张图片');
      }

      for (final attachment in meta.attachments) {
        if (attachment.base64.trim().isEmpty) {
          throw const FormatException('图片内容不能为空');
        }
        if (attachment.id.trim().isEmpty) {
          throw const FormatException('图片标识不能为空');
        }
        if (attachment.createdAt.trim().isEmpty) {
          throw const FormatException('图片创建时间不能为空');
        }
        if (attachment.mimeType != 'image/jpeg' &&
            attachment.mimeType != 'image/png') {
          throw const FormatException('图片格式仅支持 JPEG/PNG');
        }
      }

      if (type != EventType.diaper && meta.hasRash != null) {
        throw const FormatException('该记录不支持红屁屁字段');
      }
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
      'eventMeta': eventMeta?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory BabyEvent.fromJson(Map<String, dynamic> json) {
    final rawEventMeta = json['eventMeta'];
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
      eventMeta: rawEventMeta is Map<String, dynamic>
          ? EventMeta.fromJson(rawEventMeta)
          : (rawEventMeta is Map
                ? EventMeta.fromJson(rawEventMeta.cast<String, dynamic>())
                : null),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

int? _toNullableInt(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value.toString());
}
