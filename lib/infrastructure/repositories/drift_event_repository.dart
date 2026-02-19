import 'package:baby_tracker/domain/entities/baby_event.dart';
import 'package:baby_tracker/domain/repositories/event_repository.dart';
import 'package:baby_tracker/infrastructure/database/app_database.dart';
import 'package:drift/drift.dart';

class DriftEventRepository implements EventRepository {
  DriftEventRepository(this._database);

  final AppDatabase _database;

  @override
  Future<void> create(BabyEvent event) async {
    await _database
        .into(_database.eventRecords)
        .insertOnConflictUpdate(
          EventRecordsCompanion.insert(
            id: event.id,
            type: event.type.name,
            occurredAt: event.occurredAt,
            feedMethod: Value(event.feedMethod?.name),
            durationMin: Value(event.durationMin),
            amountMl: Value(event.amountMl),
            pumpStartAt: Value(event.pumpStartAt),
            pumpEndAt: Value(event.pumpEndAt),
            note: Value(event.note),
            createdAt: event.createdAt,
            updatedAt: event.updatedAt,
          ),
        );
  }

  @override
  Future<List<BabyEvent>> list(DateTime from, DateTime to) async {
    final query = _database.select(_database.eventRecords)
      ..where(
        (table) =>
            table.occurredAt.isBiggerOrEqualValue(from) &
            table.occurredAt.isSmallerThanValue(to),
      )
      ..orderBy([(table) => OrderingTerm.desc(table.occurredAt)]);

    final rows = await query.get();
    return rows.map(_toDomain).toList(growable: false);
  }

  @override
  Future<BabyEvent?> latest(EventType type) async {
    final query = _database.select(_database.eventRecords)
      ..where((table) => table.type.equals(type.name))
      ..orderBy([(table) => OrderingTerm.desc(table.occurredAt)])
      ..limit(1);

    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    return _toDomain(row);
  }

  @override
  Future<void> deleteById(String id) async {
    await (_database.delete(
      _database.eventRecords,
    )..where((table) => table.id.equals(id))).go();
  }

  BabyEvent _toDomain(EventRecord row) {
    return BabyEvent(
      id: row.id,
      type: EventTypeX.fromDb(row.type),
      occurredAt: row.occurredAt,
      feedMethod: FeedMethodX.tryFromDb(row.feedMethod),
      durationMin: row.durationMin,
      amountMl: row.amountMl,
      pumpStartAt: row.pumpStartAt,
      pumpEndAt: row.pumpEndAt,
      note: row.note,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
