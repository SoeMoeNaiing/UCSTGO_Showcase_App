import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ucstgo_showcase_flutter_app/core/database/app_database.dart';
import 'package:ucstgo_showcase_flutter_app/core/providers/showcase_providers.dart';
import 'package:ucstgo_showcase_flutter_app/core/services/cooldown_service.dart';
import 'package:ucstgo_showcase_flutter_app/core/theme/app_theme.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/feedback_screen.dart';
import 'package:ucstgo_showcase_flutter_app/features/showcase/showcase_home_screen.dart';

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
    'submits emotion feedback with pop dialog and enforces cooldown',
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

      await tester.pump();
      await tester.tap(find.text('MIND BLOWN'));
      await tester.pumpAndSettle();

      expect(find.text('THANK YOU!'), findsOneWidget);
      final rows = await db.getUnsyncedFeedback();
      expect(rows, hasLength(1));
      expect(rows.first.sentiment, 'mind_blown');

      await tester.tap(find.text('STAY HERE'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('LOVED IT'));
      await tester.pumpAndSettle();
      expect(find.text('ANTI-SPAM COOLDOWN'), findsOneWidget);
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
          home: const ShowcaseHomeScreen(),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('FEEDBACK'), findsOneWidget);

    // Rate project 1
    await tester.tap(find.text('UCSTGO Interactive Showcase'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(4));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SUBMIT RATING'));
    await tester.pumpAndSettle();

    // Trying to rate project 1 again immediately shows per-project cooldown
    await tester.tap(find.text('SUBMIT RATING'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('COOLDOWN FOR UCSTGO INTERACTIVE SHOWCASE'),
      findsOneWidget,
    );

    // Close dialog and rate a DIFFERENT project immediately
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Campus Vision & Attendance AI'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.star_outline_rounded).at(3));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SUBMIT RATING'));
    await tester.pumpAndSettle();

    final ratings = await db.getUnsyncedRatings();
    expect(ratings, hasLength(2));
  });
}
