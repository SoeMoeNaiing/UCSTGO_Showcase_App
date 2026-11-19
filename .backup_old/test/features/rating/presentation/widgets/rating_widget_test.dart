import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/widgets/rating_widget.dart';

/// Iteration 27 — RatingWidget gate (§10.7, §5.5).
void main() {
  late List<int> changes;

  Widget host({bool autofocusFirst = false}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: RatingWidget(
            onChanged: changes.add,
            autofocusFirst: autofocusFirst,
          ),
        ),
      ),
    );
  }

  setUp(() => changes = []);

  group('RatingWidget (§10.7)', () {
    testWidgets('tapping star n scores n and announces it', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host());
        await tester.pumpAndSettle();

        await tester.tap(find.bySemanticsLabel('Rate 3 stars'));
        await tester.pumpAndSettle();

        expect(changes, [3]);
        expect(find.bySemanticsLabel('Rating: 3 of 5'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('right arrow increments and caps at five', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(autofocusFirst: true));
        await tester.pumpAndSettle();

        for (var expected = 1; expected <= 5; expected++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pumpAndSettle();
          expect(find.bySemanticsLabel('Rating: $expected of 5'), findsOneWidget);
        }

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Rating: 5 of 5'), findsOneWidget);
        expect(changes, [1, 2, 3, 4, 5]);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('left arrow decrements down to zero', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(autofocusFirst: true));
        await tester.pumpAndSettle();

        for (var i = 0; i < 3; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pumpAndSettle();
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('Rating: 2 of 5'), findsOneWidget);
        expect(changes, [1, 2, 3, 2]);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('stars expose selected state and tap actions', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host());
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Rate 3 stars'));
        await tester.pumpAndSettle();

        final third = tester
            .getSemantics(find.bySemanticsLabel('Rate 3 stars'))
            .getSemanticsData();
        final fourth = tester
            .getSemantics(find.bySemanticsLabel('Rate 4 stars'))
            .getSemanticsData();

        expect(third.flagsCollection.isSelected, Tristate.isTrue);
        expect(third.hasAction(SemanticsAction.tap), isTrue);
        expect(fourth.flagsCollection.isSelected, Tristate.isFalse);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('is at least 120dp tall for TV (§5.5)', (tester) async {
      await tester.pumpWidget(host());

      final size = tester.getSize(find.byType(RatingWidget));
      expect(size.height, greaterThanOrEqualTo(120));
      await tester.pumpAndSettle();
    });

    testWidgets('five stars fit a 390dp phone without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 220));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
