import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [FeedbackEntries, ProjectRatings, ShowcaseProjects])
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        await m.createTable(showcaseProjects);
      }
    },
  );

  // ---------------------------------------------------------------------------
  // Visitor Feedback
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Project Ratings
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Controlled Project Catalog (Synced from Google Sheets / Web Uploader)
  // ---------------------------------------------------------------------------

 Future<void> upsertProjects(
    List<ShowcaseProjectsCompanion> items, {
    bool pruneMissing = false,
  }) async {
    await transaction(() async {
      final incomingIds = <String>{};
      for (final item in items) {
        if (item.projectId.present) {
          incomingIds.add(item.projectId.value);
        }
        await into(showcaseProjects).insert(
          item,
          onConflict: DoUpdate(
            (old) => ShowcaseProjectsCompanion(
              title: item.title.present ? item.title : Value(old.title as String),
              track: item.track.present ? item.track : Value(old.track as String),
              summary: item.summary.present ? item.summary : Value(old.summary as String),
              team: item.team.present ? item.team : Value(old.team as String),
              booth: item.booth.present ? item.booth : Value(old.booth as String),
              imageUrl: item.imageUrl.present
                  ? item.imageUrl
                  : Value(old.imageUrl as String?),
              techStackJson: item.techStackJson.present
                  ? item.techStackJson
                  : Value(old.techStackJson as String),
              accentHex: item.accentHex.present
                  ? item.accentHex
                  : Value(old.accentHex as String),
              sortOrder: item.sortOrder.present
                  ? item.sortOrder
                  : Value(old.sortOrder as int),
              approved: item.approved.present
                  ? item.approved
                  : Value(old.approved as bool),
              updatedAt: item.updatedAt.present
                  ? item.updatedAt
                  : Value(old.updatedAt as DateTime),
            ),
            target: [showcaseProjects.projectId],
          ),
        );
      }

      if (pruneMissing) {
        if (incomingIds.isEmpty) {
          await delete(showcaseProjects).go();
        } else {
          await (delete(
            showcaseProjects,
          )..where((t) => t.projectId.isNotIn(incomingIds))).go();
        }
      }
    });
  }

  Future<List<ShowcaseProjectRow>> getApprovedProjects() {
    return (select(showcaseProjects)
          ..where((t) => t.approved.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.title),
          ]))
        .get();
  }

  Stream<List<ShowcaseProjectRow>> watchApprovedProjects() {
    return (select(showcaseProjects)
          ..where((t) => t.approved.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.title),
          ]))
        .watch();
  }

  Future<List<String>> getActiveTracks() async {
    final rows = await getApprovedProjects();
    final seen = <String>{};
    for (final row in rows) {
      final track = row.track.trim();
      if (track.isNotEmpty) {
        seen.add(track);
      }
    }
    return seen.toList();
  }
}