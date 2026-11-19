import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/features/showcase/data/fixtures/project_fixtures.dart';
import 'package:ucstgo_showcase_flutter_app/features/showcase/domain/entities/project.dart';
import 'package:ucstgo_showcase_flutter_app/features/showcase/presentation/widgets/project_card.dart';

/// Iteration 25 — ProjectCard gate (§5.1 polaroid, §10.7).
void main() {
  final project = projectFixtures.first;
  late List<Project> selected;

  Widget host({bool autofocus = false}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ProjectCard(
            project: project,
            onSelect: selected.add,
            autofocus: autofocus,
          ),
        ),
      ),
    );
  }

  setUp(() => selected = []);

  group('ProjectCard (§10.7)', () {
    testWidgets('renders the title and blurb', (tester) async {
      await tester.pumpWidget(host());

      expect(find.text(project.title), findsOneWidget);
      expect(find.text(project.blurb), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('tap selects the card exactly once', (tester) async {
      await tester.pumpWidget(host());

      await tester.tap(find.byType(ProjectCard));
      await tester.pumpAndSettle();

      expect(selected, [project]);
    });

    testWidgets('Enter activates a focused card exactly once', (tester) async {
      await tester.pumpWidget(host(autofocus: true));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(selected, [project]);
    });

    testWidgets('is one semantic button with the blurb as a hint',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host());

        final data = tester
            .getSemantics(find.bySemanticsLabel(project.title))
            .getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
        expect(data.hint, project.blurb);

        await tester.pumpAndSettle();
      } finally {
        handle.dispose();
      }
    });
  });
}
