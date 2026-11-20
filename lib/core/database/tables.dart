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

/// Approved showcase projects synced from Google Sheets / web uploader catalog.
class ShowcaseProjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get projectId => text().unique()();
  TextColumn get title => text()();
  TextColumn get track => text()();
  TextColumn get summary => text().withDefault(const Constant(''))();
  TextColumn get team => text().withDefault(const Constant(''))();
  TextColumn get booth => text().withDefault(const Constant(''))();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get techStackJson => text().withDefault(const Constant('[]'))();
  TextColumn get accentHex => text().withDefault(const Constant('#00F5D4'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get approved => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime()();
}