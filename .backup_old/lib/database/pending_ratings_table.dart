import 'package:drift/drift.dart';

/// Durable rating queue — PROJECT_PROCESS.md §6.4, §6.6.
///
/// Mirrors [PendingFeedback] on purpose: ratings ride the same local-first
/// queue and sync engine, just with a project + score payload.
class PendingRatings extends Table {
  /// Client-generated UUID — the idempotency key (§6.5).
  TextColumn get clientId => text()();

  /// Anonymous persistent device identifier (no PII, §2.4).
  TextColumn get deviceId => text()();

  /// Showcase project identifier (matches the fixture list).
  TextColumn get projectId => text()();

  /// Star score, 1–5 inclusive (§6.1).
  IntColumn get score => integer()();

  /// Rating time in UTC.
  DateTimeColumn get createdAt => dateTime()();

  /// `SyncStatus.wireValue`; `'pending'` until the sync engine decides.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  /// Number of upload attempts so far (§6.6 backoff, capped at 6).
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Last upload attempt, UTC — diagnostics only.
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();

  /// Backoff deadline: do not retry before this instant (null = eligible).
  DateTimeColumn get nextRetryAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {clientId};
}
