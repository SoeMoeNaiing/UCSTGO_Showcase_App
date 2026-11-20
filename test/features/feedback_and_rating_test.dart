import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ucstgo_showcase_flutter_app/core/database/app_database.dart';
import 'package:ucstgo_showcase_flutter_app/core/providers/showcase_providers.dart';
import 'package:ucstgo_showcase_flutter_app/core/services/cooldown_service.dart';
import 'package:ucstgo_showcase_flutter_app/core/theme/app_theme.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/feedback_screen.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/project_rating_screen.dart';

void main() {
  late AppDatabase db;
  late SharedPreferences prefs;

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

      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('MIND BLOWN'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('FEEDBACK RECORDED.'), findsOneWidget);
      final rows = await db.getUnsyncedFeedback();
      expect(rows, hasLength(1));
      expect(rows.first.sentiment, 'mind_blown');

      await tester.tap(find.text('SKIP & HOME'));
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('LOVED IT'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('ANTI-SPAM COOLDOWN'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 5));
    },
  );

  testWidgets('enforces per-project cooldown without blocking other projects', (
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
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const ProjectRatingScreen(),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('UCSTGO Interactive Showcase'), findsOneWidget);

    await tester.tap(find.text('UCSTGO Interactive Showcase'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(4));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('SUBMIT RATING'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('SUBMIT RATING'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.textContaining('COOLDOWN FOR UCSTGO INTERACTIVE SHOWCASE'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Campus Vision & Attendance AI'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(3));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('SUBMIT RATING'));
    await tester.pump(const Duration(milliseconds: 400));

    final ratings = await db.getUnsyncedRatings();
    expect(ratings, hasLength(2));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 5));
  });
}