import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/theme/colors.dart';
import 'package:ucstgo_showcase_flutter_app/widgets/sketch_animation.dart';

class _CirclePainter extends CustomPainter {
  const _CirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide / 3,
      Paint()..color = AppColors.accentWarm,
    );
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) => false;
}

class _RecordingBackend implements SketchAnimationBackend {
  final builds = <bool>[];

  @override
  Widget build(
    BuildContext context, {
    required Widget fallback,
    required bool active,
  }) {
    builds.add(active);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [fallback, Text('active: $active')],
    );
  }
}

class _ThrowingBackend implements SketchAnimationBackend {
  const _ThrowingBackend();

  @override
  Widget build(
    BuildContext context, {
    required Widget fallback,
    required bool active,
  }) =>
      throw StateError('asset exploded');
}

class _ToggleHost extends StatefulWidget {
  const _ToggleHost({required this.backend});

  final SketchAnimationBackend backend;

  @override
  State<_ToggleHost> createState() => _ToggleHostState();
}

class _ToggleHostState extends State<_ToggleHost> {
  bool _active = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => setState(() => _active = !_active),
              child: const Text('toggle'),
            ),
            SketchAnimation(
              painter: const _CirclePainter(),
              backend: widget.backend,
              active: _active,
              fallbackKey: const Key('fallback_painter'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Iteration 30 — SketchAnimation gate (§10.8).
///
/// Proves the injectable seam and the guaranteed painter fallback without
/// ever touching an asset bundle or loading a `.riv` file in widget tests.
void main() {
  Widget host(SketchAnimationBackend backend) => _ToggleHost(backend: backend);

  group('SketchAnimation (I30)', () {
    testWidgets('no-op backend renders only the painter', (tester) async {
      await tester.pumpWidget(host(const NoOpSketchAnimationBackend()));

      expect(find.byKey(const Key('fallback_painter')), findsOneWidget);
      expect(find.byType(AnimatedScale), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('fake backend renders and advances its state', (tester) async {
      final backend = _RecordingBackend();
      await tester.pumpWidget(host(backend));

      expect(find.text('active: false'), findsOneWidget);

      await tester.tap(find.text('toggle'));
      await tester.pumpAndSettle();

      expect(find.text('active: true'), findsOneWidget);
      expect(backend.builds, [false, true]);
    });

    testWidgets('fallback backend animates the painter', (tester) async {
      await tester.pumpWidget(host(const FallbackSketchAnimationBackend()));

      expect(find.byKey(const Key('fallback_painter')), findsOneWidget);
      expect(find.byType(AnimatedScale), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('a throwing backend falls back without crashing',
        (tester) async {
      await tester.pumpWidget(host(const _ThrowingBackend()));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('fallback_painter')),
        findsOneWidget,
        reason: 'a broken backend can never blank the kiosk',
      );
      expect(tester.takeException(), isNull);
    });
  });
}
