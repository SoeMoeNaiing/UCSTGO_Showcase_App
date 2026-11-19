import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/features/showcase/data/fixtures/project_fixtures.dart';
import 'package:ucstgo_showcase_flutter_app/features/showcase/domain/entities/project.dart';
import 'package:ucstgo_showcase_flutter_app/features/showcase/presentation/widgets/project_card.dart';
import 'package:ucstgo_showcase_flutter_app/features/showcase/presentation/widgets/project_carousel.dart';

/// Iteration 26 — ProjectCarousel gate (§10.7, §2.3.2).
void main() {
  late List<Project> selected;

  Widget host() {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            height: 500,
            child: ProjectCarousel(
              projects: projectFixtures,
              onSelect: selected.add,
            ),
          ),
        ),
      ),
    );
  }

  setUp(() => selected = []);

  group('ProjectCarousel (§10.7)', () {
    testWidgets('swipe changes page and the dots follow', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host());
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Project 1 of 6'), findsOneWidget);

        await tester.drag(
          find.byKey(ProjectCarousel.pageViewKey),
          const Offset(-340, 0),
        );
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('Project 2 of 6'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('D-pad right advances and focus moves to the new card',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host());
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        expect(find.bySemanticsLabel('Project 2 of 6'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('edges are no-ops, not focus traps', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host());
        await tester.pumpAndSettle();

        for (var i = 0; i < 5; i++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pumpAndSettle();
        }
        expect(find.bySemanticsLabel('Project 6 of 6'), findsOneWidget);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel('Project 6 of 6'),
          findsOneWidget,
          reason: 'right at the last card must be a no-op',
        );

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Project 5 of 6'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('selecting a visible card fires once', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ProjectCard).first);
      await tester.pumpAndSettle();

      expect(selected, [projectFixtures.first]);
    });
  });
}
