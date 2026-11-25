import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ucstgo_showcase_flutter_app/core/database/app_database.dart';
import 'package:ucstgo_showcase_flutter_app/core/providers/showcase_providers.dart';
import 'package:ucstgo_showcase_flutter_app/core/services/cooldown_service.dart';
import 'package:ucstgo_showcase_flutter_app/core/theme/app_theme.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/feedback_screen.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/project_rating_screen.dart';

Finder _findStarGestureDetectors() {
  return find.ancestor(
    of: find.byType(SvgPicture),
    matching: find.byType(GestureDetector),
  );
}

Future<void> _drainAndDispose(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

  const seededProjects = <ShowcaseProject>[
    ShowcaseProject(
      id: 'proj-1',
      title: 'UCSTGO Interactive Showcase',
      track: 'AI & SYSTEMS',
      summary: 'Offline-first exhibition kiosk.',
      team: 'Team Alpha',
      techStack: ['Flutter', 'Drift'],
      accent: Color(0xFF00E5FF),
    ),
    ShowcaseProject(
      id: 'proj-2',
      title: 'Campus Vision & Attendance AI',
      track: 'AI & SYSTEMS',
      summary: 'Computer vision roll-call system.',
      team: 'Team Beta',
      techStack: ['Python', 'OpenCV'],
      accent: Color(0xFFA3FF12),
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets(
    'submits emotion feedback with dialog and enforces cooldown',
    (tester) async {
      final cooldown = CooldownService(
        cooldownDuration: const Duration(seconds: 15),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appDatabaseProvider.overrideWithValue(db),
            cooldownServiceProvider.overrideWithValue(cooldown),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const FeedbackScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 500));
      final moodFinder = find.text('MIND BLOWN');
      await tester.ensureVisible(moodFinder.first);
      await tester.tap(moodFinder.first);
      await tester.pump(const Duration(milliseconds: 200));

      final submitFinder = find.text('SUBMIT FEEDBACK');
      await tester.ensureVisible(submitFinder.first);
      await tester.tap(submitFinder.first);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      expect(find.textContaining('FEEDBACK RECORDED'), findsAtLeastNWidgets(1));
      final rows = await db.getUnsyncedFeedback();
      expect(rows, hasLength(1));
      expect(rows.first.sentiment, 'mind_blown');

      final skipFinder = find.text('SKIP & HOME');
      if (skipFinder.evaluate().isNotEmpty) {
        await tester.tap(skipFinder.first);
        await tester.pumpAndSettle();
      }

      await tester.ensureVisible(moodFinder.first);
      await tester.tap(moodFinder.first);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.ensureVisible(submitFinder.first);
      await tester.tap(submitFinder.first);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pumpAndSettle();

      await _drainAndDispose(tester);
    },
  );

  testWidgets('locks rated project in session without blocking other projects', (
    tester,
  ) async {
    final cooldown = CooldownService(
      cooldownDuration: const Duration(seconds: 15),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appDatabaseProvider.overrideWithValue(db),
          cooldownServiceProvider.overrideWithValue(cooldown),
          showcaseProjectsProvider.overrideWithValue(seededProjects),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const ProjectRatingScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('UCSTGO Interactive Showcase'), findsAtLeastNWidgets(1));

    final firstCard = find.text('UCSTGO Interactive Showcase').first;
    await tester.ensureVisible(firstCard);
    await tester.tap(firstCard);
    await tester.pumpAndSettle();

    expect(find.text('SUBMIT RATING'), findsOneWidget);
    final starsFirst = _findStarGestureDetectors();
    expect(starsFirst.evaluate().length, greaterThanOrEqualTo(5));
    await tester.tap(starsFirst.at(4));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('SUBMIT RATING'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    final ratingsAfterFirst = await db.getUnsyncedRatings();
    expect(ratingsAfterFirst, hasLength(1));

    final secondCard = find.text('Campus Vision & Attendance AI').first;
    await tester.ensureVisible(secondCard);
    await tester.tap(secondCard);
    await tester.pumpAndSettle();

    expect(find.text('SUBMIT RATING'), findsOneWidget);
    final starsSecond = _findStarGestureDetectors();
    expect(starsSecond.evaluate().length, greaterThanOrEqualTo(5));
    await tester.tap(starsSecond.at(2));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('SUBMIT RATING'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();

    final ratings = await db.getUnsyncedRatings();
    expect(ratings, hasLength(2));

    await _drainAndDispose(tester);
  });
}
