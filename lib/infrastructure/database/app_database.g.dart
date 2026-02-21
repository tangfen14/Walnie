// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EventRecordsTable extends EventRecords
    with TableInfo<$EventRecordsTable, EventRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feedMethodMeta = const VerificationMeta(
    'feedMethod',
  );
  @override
  late final GeneratedColumn<String> feedMethod = GeneratedColumn<String>(
    'feed_method',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationMinMeta = const VerificationMeta(
    'durationMin',
  );
  @override
  late final GeneratedColumn<int> durationMin = GeneratedColumn<int>(
    'duration_min',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMlMeta = const VerificationMeta(
    'amountMl',
  );
  @override
  late final GeneratedColumn<int> amountMl = GeneratedColumn<int>(
    'amount_ml',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pumpStartAtMeta = const VerificationMeta(
    'pumpStartAt',
  );
  @override
  late final GeneratedColumn<DateTime> pumpStartAt = GeneratedColumn<DateTime>(
    'pump_start_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pumpEndAtMeta = const VerificationMeta(
    'pumpEndAt',
  );
  @override
  late final GeneratedColumn<DateTime> pumpEndAt = GeneratedColumn<DateTime>(
    'pump_end_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _eventMetaMeta = const VerificationMeta(
    'eventMeta',
  );
  @override
  late final GeneratedColumn<String> eventMeta = GeneratedColumn<String>(
    'event_meta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    occurredAt,
    feedMethod,
    durationMin,
    amountMl,
    pumpStartAt,
    pumpEndAt,
    note,
    eventMeta,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'event_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('feed_method')) {
      context.handle(
        _feedMethodMeta,
        feedMethod.isAcceptableOrUnknown(data['feed_method']!, _feedMethodMeta),
      );
    }
    if (data.containsKey('duration_min')) {
      context.handle(
        _durationMinMeta,
        durationMin.isAcceptableOrUnknown(
          data['duration_min']!,
          _durationMinMeta,
        ),
      );
    }
    if (data.containsKey('amount_ml')) {
      context.handle(
        _amountMlMeta,
        amountMl.isAcceptableOrUnknown(data['amount_ml']!, _amountMlMeta),
      );
    }
    if (data.containsKey('pump_start_at')) {
      context.handle(
        _pumpStartAtMeta,
        pumpStartAt.isAcceptableOrUnknown(
          data['pump_start_at']!,
          _pumpStartAtMeta,
        ),
      );
    }
    if (data.containsKey('pump_end_at')) {
      context.handle(
        _pumpEndAtMeta,
        pumpEndAt.isAcceptableOrUnknown(data['pump_end_at']!, _pumpEndAtMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('event_meta')) {
      context.handle(
        _eventMetaMeta,
        eventMeta.isAcceptableOrUnknown(data['event_meta']!, _eventMetaMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EventRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      feedMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feed_method'],
      ),
      durationMin: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_min'],
      ),
      amountMl: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_ml'],
      ),
      pumpStartAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pump_start_at'],
      ),
      pumpEndAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}pump_end_at'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      eventMeta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_meta'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EventRecordsTable createAlias(String alias) {
    return $EventRecordsTable(attachedDatabase, alias);
  }
}

class EventRecord extends DataClass implements Insertable<EventRecord> {
  final String id;
  final String type;
  final DateTime occurredAt;
  final String? feedMethod;
  final int? durationMin;
  final int? amountMl;
  final DateTime? pumpStartAt;
  final DateTime? pumpEndAt;
  final String? note;
  final String? eventMeta;
  final DateTime createdAt;
  final DateTime updatedAt;
  const EventRecord({
    required this.id,
    required this.type,
    required this.occurredAt,
    this.feedMethod,
    this.durationMin,
    this.amountMl,
    this.pumpStartAt,
    this.pumpEndAt,
    this.note,
    this.eventMeta,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || feedMethod != null) {
      map['feed_method'] = Variable<String>(feedMethod);
    }
    if (!nullToAbsent || durationMin != null) {
      map['duration_min'] = Variable<int>(durationMin);
    }
    if (!nullToAbsent || amountMl != null) {
      map['amount_ml'] = Variable<int>(amountMl);
    }
    if (!nullToAbsent || pumpStartAt != null) {
      map['pump_start_at'] = Variable<DateTime>(pumpStartAt);
    }
    if (!nullToAbsent || pumpEndAt != null) {
      map['pump_end_at'] = Variable<DateTime>(pumpEndAt);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || eventMeta != null) {
      map['event_meta'] = Variable<String>(eventMeta);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  EventRecordsCompanion toCompanion(bool nullToAbsent) {
    return EventRecordsCompanion(
      id: Value(id),
      type: Value(type),
      occurredAt: Value(occurredAt),
      feedMethod: feedMethod == null && nullToAbsent
          ? const Value.absent()
          : Value(feedMethod),
      durationMin: durationMin == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMin),
      amountMl: amountMl == null && nullToAbsent
          ? const Value.absent()
          : Value(amountMl),
      pumpStartAt: pumpStartAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pumpStartAt),
      pumpEndAt: pumpEndAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pumpEndAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      eventMeta: eventMeta == null && nullToAbsent
          ? const Value.absent()
          : Value(eventMeta),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EventRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventRecord(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      feedMethod: serializer.fromJson<String?>(json['feedMethod']),
      durationMin: serializer.fromJson<int?>(json['durationMin']),
      amountMl: serializer.fromJson<int?>(json['amountMl']),
      pumpStartAt: serializer.fromJson<DateTime?>(json['pumpStartAt']),
      pumpEndAt: serializer.fromJson<DateTime?>(json['pumpEndAt']),
      note: serializer.fromJson<String?>(json['note']),
      eventMeta: serializer.fromJson<String?>(json['eventMeta']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'feedMethod': serializer.toJson<String?>(feedMethod),
      'durationMin': serializer.toJson<int?>(durationMin),
      'amountMl': serializer.toJson<int?>(amountMl),
      'pumpStartAt': serializer.toJson<DateTime?>(pumpStartAt),
      'pumpEndAt': serializer.toJson<DateTime?>(pumpEndAt),
      'note': serializer.toJson<String?>(note),
      'eventMeta': serializer.toJson<String?>(eventMeta),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  EventRecord copyWith({
    String? id,
    String? type,
    DateTime? occurredAt,
    Value<String?> feedMethod = const Value.absent(),
    Value<int?> durationMin = const Value.absent(),
    Value<int?> amountMl = const Value.absent(),
    Value<DateTime?> pumpStartAt = const Value.absent(),
    Value<DateTime?> pumpEndAt = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> eventMeta = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => EventRecord(
    id: id ?? this.id,
    type: type ?? this.type,
    occurredAt: occurredAt ?? this.occurredAt,
    feedMethod: feedMethod.present ? feedMethod.value : this.feedMethod,
    durationMin: durationMin.present ? durationMin.value : this.durationMin,
    amountMl: amountMl.present ? amountMl.value : this.amountMl,
    pumpStartAt: pumpStartAt.present ? pumpStartAt.value : this.pumpStartAt,
    pumpEndAt: pumpEndAt.present ? pumpEndAt.value : this.pumpEndAt,
    note: note.present ? note.value : this.note,
    eventMeta: eventMeta.present ? eventMeta.value : this.eventMeta,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EventRecord copyWithCompanion(EventRecordsCompanion data) {
    return EventRecord(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      feedMethod: data.feedMethod.present
          ? data.feedMethod.value
          : this.feedMethod,
      durationMin: data.durationMin.present
          ? data.durationMin.value
          : this.durationMin,
      amountMl: data.amountMl.present ? data.amountMl.value : this.amountMl,
      pumpStartAt: data.pumpStartAt.present
          ? data.pumpStartAt.value
          : this.pumpStartAt,
      pumpEndAt: data.pumpEndAt.present ? data.pumpEndAt.value : this.pumpEndAt,
      note: data.note.present ? data.note.value : this.note,
      eventMeta: data.eventMeta.present ? data.eventMeta.value : this.eventMeta,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventRecord(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('feedMethod: $feedMethod, ')
          ..write('durationMin: $durationMin, ')
          ..write('amountMl: $amountMl, ')
          ..write('pumpStartAt: $pumpStartAt, ')
          ..write('pumpEndAt: $pumpEndAt, ')
          ..write('note: $note, ')
          ..write('eventMeta: $eventMeta, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    type,
    occurredAt,
    feedMethod,
    durationMin,
    amountMl,
    pumpStartAt,
    pumpEndAt,
    note,
    eventMeta,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventRecord &&
          other.id == this.id &&
          other.type == this.type &&
          other.occurredAt == this.occurredAt &&
          other.feedMethod == this.feedMethod &&
          other.durationMin == this.durationMin &&
          other.amountMl == this.amountMl &&
          other.pumpStartAt == this.pumpStartAt &&
          other.pumpEndAt == this.pumpEndAt &&
          other.note == this.note &&
          other.eventMeta == this.eventMeta &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EventRecordsCompanion extends UpdateCompanion<EventRecord> {
  final Value<String> id;
  final Value<String> type;
  final Value<DateTime> occurredAt;
  final Value<String?> feedMethod;
  final Value<int?> durationMin;
  final Value<int?> amountMl;
  final Value<DateTime?> pumpStartAt;
  final Value<DateTime?> pumpEndAt;
  final Value<String?> note;
  final Value<String?> eventMeta;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const EventRecordsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.feedMethod = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.amountMl = const Value.absent(),
    this.pumpStartAt = const Value.absent(),
    this.pumpEndAt = const Value.absent(),
    this.note = const Value.absent(),
    this.eventMeta = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventRecordsCompanion.insert({
    required String id,
    required String type,
    required DateTime occurredAt,
    this.feedMethod = const Value.absent(),
    this.durationMin = const Value.absent(),
    this.amountMl = const Value.absent(),
    this.pumpStartAt = const Value.absent(),
    this.pumpEndAt = const Value.absent(),
    this.note = const Value.absent(),
    this.eventMeta = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EventRecord> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<DateTime>? occurredAt,
    Expression<String>? feedMethod,
    Expression<int>? durationMin,
    Expression<int>? amountMl,
    Expression<DateTime>? pumpStartAt,
    Expression<DateTime>? pumpEndAt,
    Expression<String>? note,
    Expression<String>? eventMeta,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (feedMethod != null) 'feed_method': feedMethod,
      if (durationMin != null) 'duration_min': durationMin,
      if (amountMl != null) 'amount_ml': amountMl,
      if (pumpStartAt != null) 'pump_start_at': pumpStartAt,
      if (pumpEndAt != null) 'pump_end_at': pumpEndAt,
      if (note != null) 'note': note,
      if (eventMeta != null) 'event_meta': eventMeta,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? type,
    Value<DateTime>? occurredAt,
    Value<String?>? feedMethod,
    Value<int?>? durationMin,
    Value<int?>? amountMl,
    Value<DateTime?>? pumpStartAt,
    Value<DateTime?>? pumpEndAt,
    Value<String?>? note,
    Value<String?>? eventMeta,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return EventRecordsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      occurredAt: occurredAt ?? this.occurredAt,
      feedMethod: feedMethod ?? this.feedMethod,
      durationMin: durationMin ?? this.durationMin,
      amountMl: amountMl ?? this.amountMl,
      pumpStartAt: pumpStartAt ?? this.pumpStartAt,
      pumpEndAt: pumpEndAt ?? this.pumpEndAt,
      note: note ?? this.note,
      eventMeta: eventMeta ?? this.eventMeta,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (feedMethod.present) {
      map['feed_method'] = Variable<String>(feedMethod.value);
    }
    if (durationMin.present) {
      map['duration_min'] = Variable<int>(durationMin.value);
    }
    if (amountMl.present) {
      map['amount_ml'] = Variable<int>(amountMl.value);
    }
    if (pumpStartAt.present) {
      map['pump_start_at'] = Variable<DateTime>(pumpStartAt.value);
    }
    if (pumpEndAt.present) {
      map['pump_end_at'] = Variable<DateTime>(pumpEndAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (eventMeta.present) {
      map['event_meta'] = Variable<String>(eventMeta.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventRecordsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('feedMethod: $feedMethod, ')
          ..write('durationMin: $durationMin, ')
          ..write('amountMl: $amountMl, ')
          ..write('pumpStartAt: $pumpStartAt, ')
          ..write('pumpEndAt: $pumpEndAt, ')
          ..write('note: $note, ')
          ..write('eventMeta: $eventMeta, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EventRecordsTable eventRecords = $EventRecordsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [eventRecords];
}

typedef $$EventRecordsTableCreateCompanionBuilder =
    EventRecordsCompanion Function({
      required String id,
      required String type,
      required DateTime occurredAt,
      Value<String?> feedMethod,
      Value<int?> durationMin,
      Value<int?> amountMl,
      Value<DateTime?> pumpStartAt,
      Value<DateTime?> pumpEndAt,
      Value<String?> note,
      Value<String?> eventMeta,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$EventRecordsTableUpdateCompanionBuilder =
    EventRecordsCompanion Function({
      Value<String> id,
      Value<String> type,
      Value<DateTime> occurredAt,
      Value<String?> feedMethod,
      Value<int?> durationMin,
      Value<int?> amountMl,
      Value<DateTime?> pumpStartAt,
      Value<DateTime?> pumpEndAt,
      Value<String?> note,
      Value<String?> eventMeta,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$EventRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $EventRecordsTable> {
  $$EventRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feedMethod => $composableBuilder(
    column: $table.feedMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pumpStartAt => $composableBuilder(
    column: $table.pumpStartAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pumpEndAt => $composableBuilder(
    column: $table.pumpEndAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventMeta => $composableBuilder(
    column: $table.eventMeta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $EventRecordsTable> {
  $$EventRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feedMethod => $composableBuilder(
    column: $table.feedMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMl => $composableBuilder(
    column: $table.amountMl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pumpStartAt => $composableBuilder(
    column: $table.pumpStartAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pumpEndAt => $composableBuilder(
    column: $table.pumpEndAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventMeta => $composableBuilder(
    column: $table.eventMeta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $EventRecordsTable> {
  $$EventRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get feedMethod => $composableBuilder(
    column: $table.feedMethod,
    builder: (column) => column,
  );

  GeneratedColumn<int> get durationMin => $composableBuilder(
    column: $table.durationMin,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMl =>
      $composableBuilder(column: $table.amountMl, builder: (column) => column);

  GeneratedColumn<DateTime> get pumpStartAt => $composableBuilder(
    column: $table.pumpStartAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get pumpEndAt =>
      $composableBuilder(column: $table.pumpEndAt, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get eventMeta =>
      $composableBuilder(column: $table.eventMeta, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EventRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EventRecordsTable,
          EventRecord,
          $$EventRecordsTableFilterComposer,
          $$EventRecordsTableOrderingComposer,
          $$EventRecordsTableAnnotationComposer,
          $$EventRecordsTableCreateCompanionBuilder,
          $$EventRecordsTableUpdateCompanionBuilder,
          (
            EventRecord,
            BaseReferences<_$AppDatabase, $EventRecordsTable, EventRecord>,
          ),
          EventRecord,
          PrefetchHooks Function()
        > {
  $$EventRecordsTableTableManager(_$AppDatabase db, $EventRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<String?> feedMethod = const Value.absent(),
                Value<int?> durationMin = const Value.absent(),
                Value<int?> amountMl = const Value.absent(),
                Value<DateTime?> pumpStartAt = const Value.absent(),
                Value<DateTime?> pumpEndAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> eventMeta = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventRecordsCompanion(
                id: id,
                type: type,
                occurredAt: occurredAt,
                feedMethod: feedMethod,
                durationMin: durationMin,
                amountMl: amountMl,
                pumpStartAt: pumpStartAt,
                pumpEndAt: pumpEndAt,
                note: note,
                eventMeta: eventMeta,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String type,
                required DateTime occurredAt,
                Value<String?> feedMethod = const Value.absent(),
                Value<int?> durationMin = const Value.absent(),
                Value<int?> amountMl = const Value.absent(),
                Value<DateTime?> pumpStartAt = const Value.absent(),
                Value<DateTime?> pumpEndAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> eventMeta = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => EventRecordsCompanion.insert(
                id: id,
                type: type,
                occurredAt: occurredAt,
                feedMethod: feedMethod,
                durationMin: durationMin,
                amountMl: amountMl,
                pumpStartAt: pumpStartAt,
                pumpEndAt: pumpEndAt,
                note: note,
                eventMeta: eventMeta,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EventRecordsTable,
      EventRecord,
      $$EventRecordsTableFilterComposer,
      $$EventRecordsTableOrderingComposer,
      $$EventRecordsTableAnnotationComposer,
      $$EventRecordsTableCreateCompanionBuilder,
      $$EventRecordsTableUpdateCompanionBuilder,
      (
        EventRecord,
        BaseReferences<_$AppDatabase, $EventRecordsTable, EventRecord>,
      ),
      EventRecord,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EventRecordsTableTableManager get eventRecords =>
      $$EventRecordsTableTableManager(_db, _db.eventRecords);
}
