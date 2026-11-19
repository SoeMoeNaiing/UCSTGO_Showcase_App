import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/widgets/attract_overlay.dart';

/// Iteration 31 — AttractOverlay gate (§5.1, §13).
///
/// The tester's fake clock advances timers with `pump(Duration)` — the same
/// fake-time semantics as fake_async, without nesting async zones. The
/// repeating pencil loop means tests use single pumps, never pumpAndSettle.
Widget host({Duration idle = const Duration(seconds: 20)}) {
  return MaterialApp(
    home: Scaffold(
      body: AttractOverlay(
        idleDuration: idle,
        child: Center(
          child: TextButton(
            autofocus: true,
            onPressed: () {},
            child: const Text('tap me'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('AttractOverlay (I31)', () {
    testWidgets('hidden during use, shown after the idle duration',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.pump();

      expect(find.byKey(AttractOverlay.overlayKey), findsNothing);

      await tester.pump(const Duration(seconds: 21));
      await tester.pump();

      expect(find.byKey(AttractOverlay.overlayKey), findsOneWidget);
      expect(find.text('Welcome to UCSTGO'), findsOneWidget);
    });

    testWidgets('pointer input dismisses the overlay and resets the timer',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.pump();

      await tester.pump(const Duration(seconds: 21));
      await tester.pump();
      expect(find.byKey(AttractOverlay.overlayKey), findsOneWidget);

      await tester.tap(find.text('tap me'));
      await tester.pump();
      expect(find.byKey(AttractOverlay.overlayKey), findsNothing);

      await tester.pump(const Duration(seconds: 19));
      await tester.pump();
      expect(
        find.byKey(AttractOverlay.overlayKey),
        findsNothing,
        reason: 'the timer restarted from zero',
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(find.byKey(AttractOverlay.overlayKey), findsOneWidget);
    });

    testWidgets('a key event dismisses the overlay', (tester) async {
      await tester.pumpWidget(host());
      await tester.pump();
      await tester.pump(const Duration(seconds: 21));
      await tester.pump();
      expect(find.byKey(AttractOverlay.overlayKey), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(find.byKey(AttractOverlay.overlayKey), findsNothing);
    });

    testWidgets('regular activity never triggers the overlay',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.pump();

      for (var i = 0; i < 5; i++) {
        await tester.tap(find.text('tap me'));
        await tester.pump(const Duration(seconds: 5));
      }

      expect(find.byKey(AttractOverlay.overlayKey), findsNothing);
    });

    testWidgets('the idle duration is tunable', (tester) async {
      await tester.pumpWidget(host(idle: const Duration(seconds: 2)));
      await tester.pump();

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(find.byKey(AttractOverlay.overlayKey), findsOneWidget);
    });
  });
}
