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

  test('pullCatalog filters unapproved items and sanitizes imageUrl to https',
      () async {
    final client = MockClient((request) async {
      expect(request.url.queryParameters['action'], 'projects');
      return http.Response(
        jsonEncode({
          'projects': [
            {
              'id': 'proj-1',
              'title': 'Neural Scheduler',
              'track': 'AI / ML',
              'summary': 'CPU scheduling simulator',
              'team': 'Team Core',
              'booth': 'B-12',
              'imageUrl': 'https://res.cloudinary.com/demo/image/upload/v1/a.png',
              'techStack': ['Python', 'Flutter'],
              'approved': true,
            },
            {
              'id': 'proj-2',
              'title': 'Insecure Image Project',
              'track': 'WEB',
              'imageUrl': 'http://insecure.example.com/pic.png',
              'approved': true,
            },
            {
              'id': 'proj-3',
              'title': 'Unapproved Entry',
              'track': 'SYSTEMS',
              'imageUrl': 'https://cdn.example.com/draft.png',
              'approved': false,
            },
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = SheetsSyncService(
      database: db,
      httpClient: client,
      webhookUrl: 'https://script.google.com/macros/s/test-id/exec',
    );

    final result = await service.pullCatalog();
    expect(result.ok, isTrue);
    expect(result.upsertedCount, 2);

    final stored = await db.getApprovedProjects();
    expect(stored.map((e) => e.projectId).toList(), ['proj-1', 'proj-2']);
    expect(
      stored.first.imageUrl,
      'https://res.cloudinary.com/demo/image/upload/v1/a.png',
    );
    expect(stored.last.imageUrl, isNull);
  });

  test('pullCatalog fails gracefully when unconfigured or HTTP error occurs',
      () async {
    final unconfigured = SheetsSyncService(database: db, webhookUrl: '');
    final r1 = await unconfigured.pullCatalog();
    expect(r1.ok, isFalse);

    final failingClient = MockClient((_) async => http.Response('err', 503));
    final service = SheetsSyncService(
      database: db,
      httpClient: failingClient,
      webhookUrl: 'https://script.google.com/macros/s/test-id/exec',
    );
    final r2 = await service.pullCatalog();
    expect(r2.ok, isFalse);
    expect(r2.error, 'HTTP 503');
  });
}