import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class EventRecords extends Table {
  TextColumn get id => text()();

  TextColumn get type => text()();

  DateTimeColumn get occurredAt => dateTime()();

  TextColumn get feedMethod => text().nullable()();

  IntColumn get durationMin => integer().nullable()();

  IntColumn get amountMl => integer().nullable()();

  DateTimeColumn get pumpStartAt => dateTime().nullable()();

  DateTimeColumn get pumpEndAt => dateTime().nullable()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [EventRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(eventRecords, eventRecords.pumpStartAt);
        await m.addColumn(eventRecords, eventRecords.pumpEndAt);
      }
    },
  );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'baby_tracker_db');
}
