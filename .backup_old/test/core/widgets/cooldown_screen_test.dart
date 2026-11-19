import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/app.dart';
import 'package:ucstgo_showcase_flutter_app/models/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/models/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/providers.dart';
import 'package:ucstgo_showcase_flutter_app/router/app_router.dart';
import 'package:ucstgo_showcase_flutter_app/widgets/cooldown_screen.dart';
import 'package:ucstgo_showcase_flutter_app/models/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/controllers/submit_feedback.dart';
import 'package:ucstgo_showcase_flutter_app/controllers/feedback_controller.dart';
import 'package:ucstgo_showcase_flutter_app/widgets/emoji_picker.dart';
import 'package:ucstgo_showcase_flutter_app/services/cooldown_service.dart';

class _RejectedSubmitter implements FeedbackSubmitter {
  @override
  Future<SubmissionResult> submit(EmojiChoice choice) async =>
      const SubmissionRefused(SyncStatus.rejected, 'rate limited');
}

class _FakeStorage implements CooldownStorage {
  final deadlines = <CooldownAction, DateTime>{};

  @override
  Future<DateTime?> readDeadline(CooldownAction action) async =>
      deadlines[action];

  @override
  Future<void> writeDeadline(CooldownAction action, DateTime deadline) async {
    deadlines[action] = deadline;
  }

  @override
  Future<void> clearDeadline(CooldownAction action) async =>
      deadlines.remove(action);
}

/// Iteration 32 — CooldownScreen gate (§5.1, §7, §13).
void main() {
  group('CooldownScreen (I32)', () {
    testWidgets('countdown text decrements and expiry fires once',
        (tester) async {
      final clock = StreamController<Duration>.broadcast();
      addTearDown(clock.close);
      var expiries = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CooldownScreen(
              remaining: clock.stream,
              onExpiry: () => expiries++,
            ),
          ),
        ),
      );

      for (final seconds in [30, 29, 28]) {
        clock.add(Duration(seconds: seconds));
        await tester.pumpAndSettle();
        expect(find.text('${seconds}s'), findsOneWidget);
      }
      expect(expiries, 0);

      clock.add(Duration.zero);
      await tester.pumpAndSettle();
      clock.add(Duration.zero);
      await tester.pumpAndSettle();

      expect(expiries, 1, reason: 'expiry is announced exactly once');
      expect(find.byKey(CooldownScreen.clockKey), findsOneWidget);
    });

    testWidgets('the picker is replaced during cooldown and restored on expiry',
        (tester) async {
      final clock = StreamController<Duration>.broadcast();
      final router = createAppRouter(initialLocation: '/feedback');
      addTearDown(router.dispose);
      addTearDown(clock.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            feedbackSubmitterProvider.overrideWith(
              (ref) => _RejectedSubmitter(),
            ),
            feedbackCooldownRemainingProvider.overrideWith(
              (ref) => clock.stream,
            ),
          ],
          child: KioskApp(router: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(EmojiFace.canvasKeyFor(EmojiChoice.satisfied)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CooldownScreen), findsOneWidget);
      expect(find.byType(EmojiPicker), findsNothing);

      clock.add(Duration.zero);
      await tester.pumpAndSettle();

      expect(find.byType(EmojiPicker), findsOneWidget);
      expect(find.byType(CooldownScreen), findsNothing);
    });

    test('a persisted I13 deadline drives the first countdown value', () async {
      final storage = _FakeStorage();
      final now = DateTime.utc(2026, 11, 19, 12);
      await storage.writeDeadline(
        CooldownAction.feedback,
        now.add(const Duration(seconds: 12)),
      );
      final service = CooldownService(storage: storage, now: () => now);

      expect(
        await service.remaining(CooldownAction.feedback).first,
        const Duration(seconds: 12),
      );
    });
  });
}
