import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../theme/typography.dart';

/// A designed "catch your breath" moment instead of a disabled button
/// (§5.1, §7): a doodled clock counts down the persisted deadline.
///
/// Driven by an injected [Stream] so tests never touch platform storage;
/// when the stream reaches zero (or completes) [onExpiry] fires exactly once
/// and the caller returns to the interactive screen.
class CooldownScreen extends StatefulWidget {
  const CooldownScreen({
    super.key,
    required this.remaining,
    this.onExpiry,
    this.message = 'Thanks! Take a breath before going again.',
  });

  /// Remaining time from `CooldownService.remaining(action)`.
  final Stream<Duration> remaining;

  /// Called once when the cooldown ends.
  final VoidCallback? onExpiry;

  final String message;

  static const clockKey = Key('cooldown_clock');
  static const countdownKey = Key('cooldown_countdown');

  @override
  State<CooldownScreen> createState() => _CooldownScreenState();
}

class _CooldownScreenState extends State<CooldownScreen> {
  StreamSubscription<Duration>? _subscription;
  Duration? _remaining;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _listen(widget.remaining);
  }

  @override
  void didUpdateWidget(covariant CooldownScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remaining != widget.remaining) {
      _subscription?.cancel();
      _listen(widget.remaining);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listen(Stream<Duration> stream) {
    _remaining = null;
    _expired = false;
    _subscription = stream.listen(
      (left) {
        if (!mounted) {
          return;
        }
        setState(() => _remaining = left);
        if (left <= Duration.zero) {
          _fireExpiry();
        }
      },
      onDone: _fireExpiry,
      onError: (_) => _fireExpiry(),
    );
  }

  void _fireExpiry() {
    if (_expired) {
      return;
    }
    _expired = true;
    widget.onExpiry?.call();
  }

  @override
  Widget build(BuildContext context) {
    final left = _remaining;
    final seconds = left?.inSeconds;
    final fraction = seconds == null || seconds <= 0
        ? 0.0
        : (seconds / 30).clamp(0.0, 1.0);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 160,
              child: CustomPaint(
                key: CooldownScreen.clockKey,
                painter: _ClockPainter(
                  ink: AppColors.inkPrimary,
                  glow: AppColors.idleGlow,
                  fraction: fraction,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              seconds == null ? 'Just a moment…' : '${seconds}s',
              key: CooldownScreen.countdownKey,
              style: AppTypography.display.copyWith(
                color: AppColors.inkPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: AppColors.inkSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wobbly clock face with a hand that unwinds as the deadline approaches.
class _ClockPainter extends CustomPainter {
  const _ClockPainter({
    required this.ink,
    required this.glow,
    required this.fraction,
  });

  final Color ink;
  final Color glow;
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.42;

    canvas.drawCircle(
      center,
      radius,
      Paint()..color = glow.withValues(alpha: 0.25),
    );

    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawCircle(center, radius, stroke);

    for (var tick = 0; tick < 12; tick++) {
      final angle = tick * 2 * math.pi / 12;
      final inner = radius * 0.82;
      final outer = radius * 0.92;
      canvas.drawLine(
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        stroke..strokeWidth = 1.6,
      );
    }

    final handAngle = -math.pi / 2 + (1 - fraction) * 2 * math.pi;
    canvas.drawLine(
      center,
      center +
          Offset(
            math.cos(handAngle) * radius * 0.6,
            math.sin(handAngle) * radius * 0.6,
          ),
      stroke
        ..strokeWidth = 3
        ..color = ink,
    );
    canvas.drawCircle(center, 4, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(covariant _ClockPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.ink != ink ||
      oldDelegate.glow != glow;
}
