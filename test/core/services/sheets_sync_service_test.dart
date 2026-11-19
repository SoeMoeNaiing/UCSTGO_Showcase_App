import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ucstgo_showcase_flutter_app/core/database/app_database.dart';
import 'package:ucstgo_showcase_flutter_app/core/services/sheets_sync_service.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'skips network when webhook URL is empty and keeps rows unsynced',
    () async {
      var called = false;
      final client = MockClient((request) async {
        called = true;
        return http.Response('ok', 200);
      });

      await db.insertFeedback(
        eventId: 'fb-offline-1',
        deviceId: 'dev-1',
        sentiment: 'loved',
      );

      final service = SheetsSyncService(
        database: db,
        httpClient: client,
        webhookUrl: '',
      );

      final report = await service.syncPending();
      expect(called, isFalse);
      expect(report.totalSynced, 0);
      expect((await db.getUnsyncedFeedback()), hasLength(1));
    },
  );

  test(
    'posts pending feedback & ratings and marks 2xx items as synced',
    () async {
      final receivedTypes = <String>[];
      final client = MockClient((request) async {
        final decoded = jsonDecode(request.body) as Map<String, dynamic>;
        receivedTypes.add(decoded['type'] as String);
        return http.Response('{"ok":true}', 200);
      });

      await db.insertFeedback(
        eventId: 'fb-1',
        deviceId: 'dev-1',
        sentiment: 'okay',
      );
      await db.insertRating(
        eventId: 'rt-1',
        deviceId: 'dev-1',
        projectId: 'p-1',
        projectTitle: 'Hostel Manager',
        score: 4,
      );

      final service = SheetsSyncService(
        database: db,
        httpClient: client,
        webhookUrl: 'https://script.google.com/macros/s/test/exec',
      );

      final report = await service.syncPending();
      expect(report.syncedFeedback, 1);
      expect(report.syncedRatings, 1);
      expect(report.failedCount, 0);
      expect(receivedTypes, ['feedback', 'rating']);
      expect(await db.getUnsyncedFeedback(), isEmpty);
      expect(await db.getUnsyncedRatings(), isEmpty);
    },
  );

  test('keeps failed items unsynced when webhook returns 500', () async {
    final client = MockClient((request) async => http.Response('err', 500));

    await db.insertFeedback(
      eventId: 'fb-fail',
      deviceId: 'dev-1',
      sentiment: 'not_great',
    );

    final service = SheetsSyncService(
      database: db,
      httpClient: client,
      webhookUrl: 'https://script.google.com/macros/s/test/exec',
    );

    final report = await service.syncPending();
    expect(report.totalSynced, 0);
    expect(report.failedCount, 1);
    expect(await db.getUnsyncedFeedback(), hasLength(1));
  });
}
