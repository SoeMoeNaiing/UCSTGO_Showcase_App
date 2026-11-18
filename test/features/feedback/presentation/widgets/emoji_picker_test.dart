import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/widgets/emoji_picker.dart';

void _noop(EmojiChoice _) {}

/// Iteration 18–19 — EmojiPicker (PROJECT_PROCESS.md §5.1, §5.5, §7).
///
/// Exactly three sketch faces with one semantic node each, now interactive:
/// tap and keyboard activate, arrow keys traverse, focus visibly draws a
/// rough frame, and a 2s client throttle drops double-taps before the
/// callback can submit twice.
void main() {
  Widget host(Widget child, {double width = 390}) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );
  }

  group('EmojiPicker (§5.1, §5.5)', () {
    testWidgets('renders exactly three faces in sentiment order',
        (tester) async {
      await tester.pumpWidget(host(EmojiPicker(onSelected: _noop)));

      expect(find.byType(EmojiFace), findsNWidgets(3));
      expect(
        tester
            .widgetList<EmojiFace>(find.byType(EmojiFace))
            .map((face) => face.choice),
        [
          EmojiChoice.satisfied,
          EmojiChoice.neutral,
          EmojiChoice.dissatisfied,
        ],
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('exposes one semantic label per face', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(EmojiPicker(onSelected: _noop)));

        expect(find.bySemanticsLabel('Satisfied'), findsOneWidget);
        expect(find.bySemanticsLabel('Neutral'), findsOneWidget);
        expect(find.bySemanticsLabel('Dissatisfied'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('shows friendly visible copy under every face',
        (tester) async {
      await tester.pumpWidget(host(EmojiPicker(onSelected: _noop)));

      expect(find.text('Loved it'), findsOneWidget);
      expect(find.text('Okay'), findsOneWidget);
      expect(find.text('Not great'), findsOneWidget);
    });

    testWidgets('faces stay square and large on a narrow phone',
        (tester) async {
      await tester.pumpWidget(
        host(EmojiPicker(onSelected: _noop), width: 320),
      );

      expect(tester.takeException(), isNull);
      for (final choice in EmojiChoice.values) {
        final size = tester.getSize(
          find.byKey(EmojiFace.canvasKeyFor(choice)),
        );
        expect(size.width, size.height, reason: '${choice.name} must be square');
        expect(
          size.width,
          greaterThanOrEqualTo(88),
          reason: '${choice.name} must stay finger-sized at 320dp',
        );
      }
    });

    testWidgets('caps face size on wide screens (§5.5 10-foot sizing)',
        (tester) async {
      await tester.pumpWidget(
        host(EmojiPicker(onSelected: _noop), width: 900),
      );

      final size = tester.getSize(
        find.byKey(EmojiFace.canvasKeyFor(EmojiChoice.satisfied)),
      );
      expect(size.width, 180, reason: 'default cap keeps the row readable');
      expect(tester.takeException(), isNull);
    });

    testWidgets('honours a TV-sized face cap without touching the painter',
        (tester) async {
      await tester.pumpWidget(
        host(
          EmojiPicker(onSelected: _noop, maxFaceSize: 240),
          width: 1200,
        ),
      );

      final size = tester.getSize(
        find.byKey(EmojiFace.canvasKeyFor(EmojiChoice.neutral)),
      );
      expect(size.width, 240);
    });
  });

  group('EmojiPicker interaction (§7)', () {
    late List<EmojiChoice> selected;

    setUp(() => selected = []);

    Widget picker({bool autofocusFirst = false}) => host(
          EmojiPicker(
            onSelected: selected.add,
            autofocusFirst: autofocusFirst,
          ),
        );

    Finder canvas(EmojiChoice choice) =>
        find.byKey(EmojiFace.canvasKeyFor(choice));
    Finder focusBox(EmojiChoice choice) =>
        find.byKey(EmojiFace.focusBoxKeyFor(choice));

    testWidgets('tap selects exactly once', (tester) async {
      await tester.pumpWidget(picker());

      await tester.tap(canvas(EmojiChoice.satisfied));
      await tester.pump();

      expect(selected, [EmojiChoice.satisfied]);
    });

    testWidgets('double-tap inside the 2s window fires once', (tester) async {
      await tester.pumpWidget(picker());

      await tester.tap(canvas(EmojiChoice.satisfied));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(canvas(EmojiChoice.satisfied));
      await tester.pump();

      expect(selected, [EmojiChoice.satisfied]);
    });

    testWidgets('a different face inside the window is also ignored',
        (tester) async {
      await tester.pumpWidget(picker());

      await tester.tap(canvas(EmojiChoice.satisfied));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(canvas(EmojiChoice.dissatisfied));
      await tester.pump();

      expect(
        selected,
        [EmojiChoice.satisfied],
        reason: 'the picker is a one-shot action across all three faces',
      );
    });

    testWidgets('selecting resumes after the window', (tester) async {
      await tester.pumpWidget(picker());

      await tester.tap(canvas(EmojiChoice.satisfied));
      await tester.pump(const Duration(seconds: 2, milliseconds: 1));
      await tester.tap(canvas(EmojiChoice.neutral));
      await tester.pump();

      expect(selected, [EmojiChoice.satisfied, EmojiChoice.neutral]);
    });

    testWidgets('Enter activates the focused face', (tester) async {
      await tester.pumpWidget(picker(autofocusFirst: true));
      await tester.pump();
      expect(focusBox(EmojiChoice.satisfied), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(selected, [EmojiChoice.satisfied]);
    });

    testWidgets('arrow keys move focus and the highlight', (tester) async {
      await tester.pumpWidget(picker(autofocusFirst: true));
      await tester.pump();
      expect(focusBox(EmojiChoice.satisfied), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusBox(EmojiChoice.neutral), findsOneWidget);
      expect(focusBox(EmojiChoice.satisfied), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusBox(EmojiChoice.dissatisfied), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusBox(EmojiChoice.neutral), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('focus frame only appears while focused', (tester) async {
      await tester.pumpWidget(picker());
      expect(focusBox(EmojiChoice.satisfied), findsNothing);

      await tester.tap(canvas(EmojiChoice.satisfied));
      await tester.pump();
      expect(
        focusBox(EmojiChoice.satisfied),
        findsOneWidget,
        reason: 'touch leaves the same visible focus as D-pad navigation',
      );

      await tester.pumpAndSettle();
    });

    testWidgets('semantics is a button with a tap action', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(picker());

        final data = tester
            .getSemantics(find.bySemanticsLabel('Satisfied'))
            .getSemanticsData();
        expect(data.flagsCollection.isButton, isTrue);
        expect(data.hasAction(SemanticsAction.tap), isTrue);
      } finally {
        handle.dispose();
      }
    });
  });
}
