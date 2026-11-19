import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/widgets/rate_projects_prompt.dart';

/// Iteration 23 — RateProjectsPrompt gate (PROJECT_PROCESS.md §5.1, §2.3.2).
///
/// Both actions are single-tap buttons reachable by touch and D-pad, with
/// the same shared sketch focus frame the emoji faces use.
void main() {
  late int yesCalls;
  late int skipCalls;

  Widget host({bool autofocusYes = false}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: RateProjectsPrompt(
            onYes: () => yesCalls++,
            onSkip: () => skipCalls++,
            autofocusYes: autofocusYes,
          ),
        ),
      ),
    );
  }

  setUp(() {
    yesCalls = 0;
    skipCalls = 0;
  });

  group('RateProjectsPrompt (§5.1)', () {
    testWidgets('renders the question and both actions', (tester) async {
      await tester.pumpWidget(host());

      expect(find.text('Rate our projects?'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Yes fires onYes exactly once', (tester) async {
      await tester.pumpWidget(host());

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(yesCalls, 1);
      expect(skipCalls, 0);
    });

    testWidgets('Skip fires onSkip exactly once', (tester) async {
      await tester.pumpWidget(host());

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(skipCalls, 1);
      expect(yesCalls, 0);
    });

    testWidgets('arrow keys traverse both buttons and Enter activates',
        (tester) async {
      await tester.pumpWidget(host(autofocusYes: true));
      await tester.pump();
      expect(
        find.byKey(RateProjectsPrompt.focusFrameKey('yes')),
        findsOneWidget,
      );
      expect(
        find.byKey(RateProjectsPrompt.focusFrameKey('skip')),
        findsNothing,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        find.byKey(RateProjectsPrompt.focusFrameKey('skip')),
        findsOneWidget,
      );
      expect(
        find.byKey(RateProjectsPrompt.focusFrameKey('yes')),
        findsNothing,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(
        find.byKey(RateProjectsPrompt.focusFrameKey('yes')),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(yesCalls, 1);
      expect(skipCalls, 0);
      await tester.pumpAndSettle();
    });

    testWidgets('both actions are semantic buttons with tap actions',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host());

        for (final label in ['Yes', 'Skip']) {
          final data = tester
              .getSemantics(find.bySemanticsLabel(label))
              .getSemanticsData();
          expect(data.flagsCollection.isButton, isTrue);
          expect(data.hasAction(SemanticsAction.tap), isTrue);
        }

        await tester.pumpAndSettle();
      } finally {
        handle.dispose();
      }
    });
  });
}
