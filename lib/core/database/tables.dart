import 'package:drift/drift.dart';

/// Visitor feedback rows persisted locally and queued for Google Sheets sync.
class FeedbackEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventId => text().unique()();
  TextColumn get deviceId => text()();
  TextColumn get sentiment => text()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}

/// Project rating rows persisted locally and queued for Google Sheets sync.
class ProjectRatings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get eventId => text().unique()();
  TextColumn get deviceId => text()();
  TextColumn get projectId => text()();
  TextColumn get projectTitle => text()();
  IntColumn get score => integer()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}
