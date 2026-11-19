import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [FeedbackEntries, ProjectRatings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Persistent local SQLite database for app/kiosk runtime.
  factory AppDatabase.open({String name = 'ucstgo_showcase_db'}) {
    return AppDatabase(driftDatabase(name: name));
  }

  /// Ephemeral in-memory database for unit tests.
  factory AppDatabase.memory() {
    return AppDatabase(NativeDatabase.memory());
  }

  @override
  int get schemaVersion => 1;

  Future<int> insertFeedback({
    required String eventId,
    required String deviceId,
    required String sentiment,
    String note = '',
    DateTime? createdAt,
  }) {
    return into(feedbackEntries).insert(
      FeedbackEntriesCompanion.insert(
        eventId: eventId,
        deviceId: deviceId,
        sentiment: sentiment,
        note: Value(note),
        createdAt: createdAt ?? DateTime.now().toUtc(),
      ),
    );
  }

  Future<List<FeedbackEntry>> getUnsyncedFeedback() {
    return (select(
      feedbackEntries,
    )..where((t) => t.synced.equals(false))).get();
  }

  Future<void> markFeedbackSynced(Iterable<String> eventIds) async {
    final ids = eventIds.toList();
    if (ids.isEmpty) {
      return;
    }
    await (update(feedbackEntries)..where((t) => t.eventId.isIn(ids))).write(
      const FeedbackEntriesCompanion(synced: Value(true)),
    );
  }

  Future<int> insertRating({
    required String eventId,
    required String deviceId,
    required String projectId,
    required String projectTitle,
    required int score,
    DateTime? createdAt,
  }) {
    return into(projectRatings).insert(
      ProjectRatingsCompanion.insert(
        eventId: eventId,
        deviceId: deviceId,
        projectId: projectId,
        projectTitle: projectTitle,
        score: score,
        createdAt: createdAt ?? DateTime.now().toUtc(),
      ),
    );
  }

  Future<List<ProjectRating>> getUnsyncedRatings() {
    return (select(projectRatings)..where((t) => t.synced.equals(false))).get();
  }

  Future<void> markRatingsSynced(Iterable<String> eventIds) async {
    final ids = eventIds.toList();
    if (ids.isEmpty) {
      return;
    }
    await (update(projectRatings)..where((t) => t.eventId.isIn(ids))).write(
      const ProjectRatingsCompanion(synced: Value(true)),
    );
  }
}
