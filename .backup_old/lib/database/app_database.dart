import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import './pending_feedback_table.dart';
import './pending_ratings_table.dart';

part 'app_database.g.dart';

/// Offline-first local queue — PROJECT_PROCESS.md §6.4, §6.6.
///
/// Both submission types share one database so the sync engine drains
/// them through a single connection and one schema version (§4.1 places
/// the queue under `features/feedback/data/local/`).
@DriftDatabase(tables: [PendingFeedback, PendingRatings])
class AppDatabase extends _$AppDatabase {
  /// Production database stored in the app documents directory.
  AppDatabase() : super(driftDatabase(name: 'ucstgo_kiosk'));

  /// Test/DI constructor — pass `NativeDatabase.memory()` for isolation,
  /// or a fake executor when unit-testing the data sources.
  AppDatabase.withExecutor(super.e);

  @override
  int get schemaVersion => 1;

  /// Store timestamps as ISO-8601 text instead of unix seconds.
  ///
  /// The domain requires UTC (§6.5) and the queue orders by `createdAt`;
  /// text storage round-trips the UTC flag instead of silently reading
  /// back local time. All writes are UTC, so lexicographic order = time
  /// order for the queue.
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}
