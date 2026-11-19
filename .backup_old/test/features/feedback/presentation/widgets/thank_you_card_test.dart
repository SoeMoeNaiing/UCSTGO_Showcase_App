import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/widgets/thank_you_card.dart';

/// Iteration 22 — ThankYouCard gate (PROJECT_PROCESS.md §5.1).
///
/// The card is render-only: I24 decides when to show it from the success
/// state. These tests prove the copy, the two doodles, the single semantic
/// node, and a clean trip through the `flutter_animate` entrance.
Widget host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

class _SuccessHost extends StatefulWidget {
  const _SuccessHost();

  @override
  State<_SuccessHost> createState() => _SuccessHostState();
}

class _SuccessHostState extends State<_SuccessHost> {
  bool _success = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_success) const ThankYouCard() else const Text('idle'),
              TextButton(
                onPressed: () => setState(() => _success = true),
                child: const Text('show'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  group('ThankYouCard (§5.1)', () {
    testWidgets('renders the scribbled message and both doodles',
        (tester) async {
      await tester.pumpWidget(host(const ThankYouCard()));

      expect(find.text('Thank you!'), findsOneWidget);
      expect(find.byKey(ThankYouCard.bubbleKey), findsOneWidget);
      expect(find.byKey(ThankYouCard.characterKey), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('announces one thank-you message', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(const ThankYouCard()));

        expect(find.bySemanticsLabel('Thank you!'), findsOneWidget);

        await tester.pumpAndSettle();
      } finally {
        handle.dispose();
      }
    });

    testWidgets('appears when the success state shows it', (tester) async {
      await tester.pumpWidget(const _SuccessHost());
      expect(find.byType(ThankYouCard), findsNothing);

      await tester.tap(find.text('show'));
      await tester.pump();

      expect(find.byType(ThankYouCard), findsOneWidget);
      expect(find.text('Thank you!'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('pumps through the entrance without exceptions',
        (tester) async {
      await tester.pumpWidget(host(const ThankYouCard()));

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
