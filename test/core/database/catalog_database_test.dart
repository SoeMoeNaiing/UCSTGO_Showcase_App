import 'package:drift/drift.dart' show Value;
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

  test('upserts approved projects, derives active tracks, and prunes removed rows',
      () async {
    final now = DateTime.now().toUtc();

    await db.upsertProjects([
      ShowcaseProjectsCompanion.insert(
        projectId: 'p1',
        title: 'Alpha Project',
        track: 'AI / ML',
        imageUrl: const Value('https://cdn.example.com/alpha.webp'),
        sortOrder: const Value(2),
        approved: const Value(true),
        updatedAt: now,
      ),
      ShowcaseProjectsCompanion.insert(
        projectId: 'p2',
        title: 'Beta Project',
        track: 'MOBILE & UI',
        sortOrder: const Value(1),
        approved: const Value(true),
        updatedAt: now,
      ),
      ShowcaseProjectsCompanion.insert(
        projectId: 'p3',
        title: 'Pending Draft',
        track: 'SYSTEMS',
        approved: const Value(false),
        updatedAt: now,
      ),
    ]);

    final approved = await db.getApprovedProjects();
    expect(approved.map((e) => e.projectId).toList(), ['p2', 'p1']);
    expect(approved.first.imageUrl, isNull);
    expect(approved.last.imageUrl, 'https://cdn.example.com/alpha.webp');

    final tracks = await db.getActiveTracks();
    expect(tracks, ['MOBILE & UI', 'AI / ML']);

    // Prune p1 when syncing a catalog that only contains p2
    await db.upsertProjects(
      [
        ShowcaseProjectsCompanion.insert(
          projectId: 'p2',
          title: 'Beta Project Updated',
          track: 'MOBILE & UI',
          sortOrder: const Value(1),
          approved: const Value(true),
          updatedAt: now,
        ),
      ],
      pruneMissing: true,
    );

    final afterPrune = await db.getApprovedProjects();
    expect(afterPrune, hasLength(1));
    expect(afterPrune.single.projectId, 'p2');
    expect(afterPrune.single.title, 'Beta Project Updated');
  });
}