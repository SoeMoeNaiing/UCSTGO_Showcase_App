import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/widgets/emoji_picker.dart';

/// Iteration 18 — static EmojiPicker (PROJECT_PROCESS.md §5.1, §5.5).
///
/// The first UI component: exactly three sketch faces, ordered
/// satisfied → neutral → dissatisfied, each a single semantic node with a
/// visible label underneath. Render-only, so nothing here fires callbacks.
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
      await tester.pumpWidget(host(const EmojiPicker()));

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
        await tester.pumpWidget(host(const EmojiPicker()));

        expect(find.bySemanticsLabel('Satisfied'), findsOneWidget);
        expect(find.bySemanticsLabel('Neutral'), findsOneWidget);
        expect(find.bySemanticsLabel('Dissatisfied'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('shows friendly visible copy under every face',
        (tester) async {
      await tester.pumpWidget(host(const EmojiPicker()));

      expect(find.text('Loved it'), findsOneWidget);
      expect(find.text('Okay'), findsOneWidget);
      expect(find.text('Not great'), findsOneWidget);
    });

    testWidgets('faces stay square and large on a narrow phone',
        (tester) async {
      await tester.pumpWidget(host(const EmojiPicker(), width: 320));

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
      await tester.pumpWidget(host(const EmojiPicker(), width: 900));

      final size = tester.getSize(
        find.byKey(EmojiFace.canvasKeyFor(EmojiChoice.satisfied)),
      );
      expect(size.width, 180, reason: 'default cap keeps the row readable');
      expect(tester.takeException(), isNull);
    });

    testWidgets('honours a TV-sized face cap without touching the painter',
        (tester) async {
      await tester.pumpWidget(
        host(const EmojiPicker(maxFaceSize: 240), width: 1200),
      );

      final size = tester.getSize(
        find.byKey(EmojiFace.canvasKeyFor(EmojiChoice.neutral)),
      );
      expect(size.width, 240);
    });
  });
}
