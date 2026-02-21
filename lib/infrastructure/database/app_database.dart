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

  TextColumn get eventMeta => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [EventRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(eventRecords, eventRecords.pumpStartAt);
        await m.addColumn(eventRecords, eventRecords.pumpEndAt);
      }

      if (from < 3) {
        await m.addColumn(eventRecords, eventRecords.eventMeta);
        await customStatement('''
          UPDATE event_records
          SET event_meta =
            '{"schemaVersion":1,"status":"mixed","changedDiaper":true,"hasRash":false,"attachments":[]}'
          WHERE type = 'diaper' AND event_meta IS NULL
        ''');
      }

      if (from < 4) {
        await customStatement('''
          UPDATE event_records
          SET type = 'diaper',
              event_meta = '{"schemaVersion":1,"status":"poop","changedDiaper":true,"attachments":[]}'
          WHERE type = 'poop'
        ''');
        await customStatement('''
          UPDATE event_records
          SET type = 'diaper',
              event_meta = '{"schemaVersion":1,"status":"pee","changedDiaper":true,"attachments":[]}'
          WHERE type = 'pee'
        ''');
        await customStatement('''
          UPDATE event_records
          SET event_meta =
            '{"schemaVersion":1,"status":"mixed","changedDiaper":true,"hasRash":false,"attachments":[]}'
          WHERE type = 'diaper' AND (event_meta IS NULL OR TRIM(event_meta) = '')
        ''');
      }
    },
  );
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'baby_tracker_db');
}
