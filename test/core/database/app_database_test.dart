import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  test('inserts, queries, and marks feedback entries as synced', () async {
    await db.insertFeedback(
      eventId: 'fb-1',
      deviceId: 'kiosk-01',
      sentiment: 'loved',
      note: 'Great showcase',
    );

    final unsyncedBefore = await db.getUnsyncedFeedback();
    expect(unsyncedBefore, hasLength(1));
    expect(unsyncedBefore.first.sentiment, 'loved');
    expect(unsyncedBefore.first.synced, isFalse);

    await db.markFeedbackSynced(['fb-1']);

    final unsyncedAfter = await db.getUnsyncedFeedback();
    expect(unsyncedAfter, isEmpty);
  });

  test('inserts, queries, and marks project ratings as synced', () async {
    await db.insertRating(
      eventId: 'rt-1',
      deviceId: 'kiosk-01',
      projectId: 'proj-ai',
      projectTitle: 'Campus Vision AI',
      score: 5,
    );

    final unsyncedBefore = await db.getUnsyncedRatings();
    expect(unsyncedBefore, hasLength(1));
    expect(unsyncedBefore.first.score, 5);
    expect(unsyncedBefore.first.synced, isFalse);

    await db.markRatingsSynced(['rt-1']);

    final unsyncedAfter = await db.getUnsyncedRatings();
    expect(unsyncedAfter, isEmpty);
  });
}
