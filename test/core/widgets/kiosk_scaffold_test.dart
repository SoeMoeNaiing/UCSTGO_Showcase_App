import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/theme/app_colors.dart';
import 'package:ucstgo_showcase_flutter_app/core/widgets/kiosk_scaffold.dart';

/// Iteration 6 — KioskScaffold guard (PROJECT_PROCESS.md §5.1, §5.5).
///
/// Proves the shared kiosk surface: paper background, dot-grid texture,
/// phone edge-to-edge default, 5% TV overscan inset, and the decorative
/// background slot used later by the idle attract mode.
void main() {
  const contentKey = Key('content');

  group('KioskScaffold (§5.1, §5.5)', () {
    testWidgets('renders its child on the paper background', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KioskScaffold(child: Text('hello kiosk')),
        ),
      );

      expect(find.text('hello kiosk'), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.paperBackground);
    });

    testWidgets('paints the dot-grid texture without exceptions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KioskScaffold(child: SizedBox.expand()),
        ),
      );

      // The painter runs during the pump; a throw would fail the test.
      expect(tester.takeException(), isNull);
      expect(find.byKey(KioskScaffold.gridKey), findsOneWidget);
    });

    testWidgets('grid can be disabled for clean captures', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KioskScaffold(
            showGrid: false,
            child: SizedBox.expand(),
          ),
        ),
      );

      expect(find.byKey(KioskScaffold.gridKey), findsNothing);
    });

    testWidgets('phone default is edge-to-edge (no overscan inset)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KioskScaffold(
            child: SizedBox.expand(key: contentKey),
          ),
        ),
      );

      final rect = tester.getRect(find.byKey(contentKey));
      expect(rect.left, moreOrLessEquals(0));
      expect(rect.top, moreOrLessEquals(0));
      expect(rect.width, moreOrLessEquals(800));
      expect(rect.height, moreOrLessEquals(600));
    });

    testWidgets('TV mode insets by 5% of the shortest side', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KioskScaffold(
            overscan: 0.05,
            child: SizedBox.expand(key: contentKey),
          ),
        ),
      );

      // Test surface is 800x600 → shortest side 600 → 30dp inset.
      final rect = tester.getRect(find.byKey(contentKey));
      expect(rect.left, moreOrLessEquals(30));
      expect(rect.top, moreOrLessEquals(30));
      expect(rect.width, moreOrLessEquals(800 - 60));
      expect(rect.height, moreOrLessEquals(600 - 60));
    });

    testWidgets('decorative background layer renders behind content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: KioskScaffold(
            background: ColoredBox(
              key: Key('bg'),
              color: Colors.transparent,
            ),
            child: Text('content'),
          ),
        ),
      );

      expect(find.byKey(const Key('bg')), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });
  });
}
