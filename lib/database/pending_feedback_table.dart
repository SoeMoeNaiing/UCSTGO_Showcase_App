import 'package:drift/drift.dart';

/// Durable feedback queue — PROJECT_PROCESS.md §6.4, §6.6.
///
/// One row per visitor submission. The row is written **before** any
/// network call and survives app restarts; the local queue is the source
/// of truth, not the server.
class PendingFeedback extends Table {
  /// Client-generated UUID — the idempotency key (§6.5). Used as the
  /// primary key so a replay can never insert the same submission twice.
  TextColumn get clientId => text()();

  /// Anonymous persistent device identifier (no PII, §2.4).
  TextColumn get deviceId => text()();

  /// `EmojiChoice.wireValue` — `'satisfied'` / `'neutral'` / `'dissatisfied'`.
  TextColumn get emojiChoice => text()();

  /// Submission time in UTC (the entity enforces this, §6.5).
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
