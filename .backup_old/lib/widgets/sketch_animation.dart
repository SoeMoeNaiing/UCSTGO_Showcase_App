import 'package:flutter/material.dart';

/// An injectable animated-visual backend (I30, §5.1).
///
/// Every backend must be able to render the supplied [fallback] painter —
/// a kiosk must never show a broken or empty animation asset.
abstract interface class SketchAnimationBackend {
  Widget build(
    BuildContext context, {
    required Widget fallback,
    required bool active,
  });
}

/// Pure no-op: renders the painter unchanged. Use in tests and anywhere an
/// animation is not wanted (no loaders, no tickers, no timers).
final class NoOpSketchAnimationBackend implements SketchAnimationBackend {
  const NoOpSketchAnimationBackend();

  @override
  Widget build(
    BuildContext context, {
    required Widget fallback,
    required bool active,
  }) => fallback;
}

/// The production default while real `.riv` art is unavailable: the
/// hand-drawn painter itself gets a small animated response to `active`.
final class FallbackSketchAnimationBackend implements SketchAnimationBackend {
  const FallbackSketchAnimationBackend();

  @override
  Widget build(
    BuildContext context, {
    required Widget fallback,
    required bool active,
  }) {
    return AnimatedScale(
      scale: active ? 1.06 : 1.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      child: AnimatedOpacity(
        opacity: active ? 1 : 0.85,
        duration: const Duration(milliseconds: 250),
        child: fallback,
      ),
    );
  }
}

/// A sketch visual with two states and a guaranteed `CustomPainter` fallback.
///
/// The backend is injected so tests can be hermetic and a missing or broken
/// `.riv` asset can never leave a blank kiosk screen.
class SketchAnimation extends StatelessWidget {
  const SketchAnimation({
    super.key,
    required this.painter,
    this.backend = const FallbackSketchAnimationBackend(),
    this.active = false,
    this.fallbackKey,
    this.size,
  });

  /// The always-available hand-drawn visual.
  final CustomPainter painter;

  /// How the visual is animated; defaults to the painter fallback.
  final SketchAnimationBackend backend;

  /// Current state (e.g. a selected face or a waving character).
  final bool active;

  /// Key preserved on the fallback painter for existing component tests.
  final Key? fallbackKey;

  /// Optional square size constraint.
  final double? size;

  @override
  Widget build(BuildContext context) {
    Widget fallback = CustomPaint(key: fallbackKey, painter: painter);
    if (size != null) {
      fallback = SizedBox.square(dimension: size!, child: fallback);
    }

    try {
      return backend.build(context, fallback: fallback, active: active);
    } catch (_) {
      // A hostile/buggy backend cannot break the kiosk.
      return fallback;
    }
  }
}
