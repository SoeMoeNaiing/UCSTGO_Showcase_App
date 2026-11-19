import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/app.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/usecases/submit_feedback.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/controllers/feedback_controller.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/widgets/emoji_picker.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/widgets/rate_projects_prompt.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/widgets/thank_you_card.dart';

class _FakeSubmitter implements FeedbackSubmitter {
  final calls = <EmojiChoice>[];
  SubmissionResult result = const SubmissionAccepted(SyncStatus.pending);

  @override
  Future<SubmissionResult> submit(EmojiChoice choice) async {
    calls.add(choice);
    return result;
  }
}

/// Iteration 24 — full-flow E2E (§10.6, milestone M4).
///
/// The entire app boots with only the single submitter seam faked: real
/// router, real controller, real use case wiring shape and real widgets.
void main() {
  late _FakeSubmitter submitter;

  Widget host() => ProviderScope(
        overrides: [feedbackSubmitterProvider.overrideWith((ref) => submitter)],
        child: const KioskApp(),
      );

  setUp(() => submitter = _FakeSubmitter());

  group('FeedbackScreen E2E (§10.6)', () {
    testWidgets('initial focus lands on the first face', (tester) async {
      await tester.pumpWidget(host());
      await tester.pump();

      expect(find.byType(EmojiPicker), findsOneWidget);
      expect(
        find.byKey(EmojiFace.focusBoxKeyFor(EmojiChoice.satisfied)),
        findsOneWidget,
        reason: 'D-pad/TV visitors land on the happy face',
      );
    });

    testWidgets('tap → submit → thank-you → prompt → Skip → picker',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.pump();

      await tester.tap(
        find.byKey(EmojiFace.canvasKeyFor(EmojiChoice.satisfied)),
      );
      await tester.pump();

      expect(submitter.calls, [EmojiChoice.satisfied]);
      expect(find.byType(ThankYouCard), findsOneWidget);
      expect(find.text('Thank you!'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2, milliseconds: 1));
      expect(find.byType(RateProjectsPrompt), findsOneWidget);

      await tester.tap(find.text('Skip'));
      await tester.pump();

      expect(find.byType(EmojiPicker), findsOneWidget);
      expect(find.byType(ThankYouCard), findsNothing);
      expect(find.byType(RateProjectsPrompt), findsNothing);
      expect(submitter.calls, [EmojiChoice.satisfied]);
    });

    testWidgets('offline acceptance still reaches the thank-you',
        (tester) async {
      submitter.result = const SubmissionAccepted(SyncStatus.pending);
      await tester.pumpWidget(host());
      await tester.pump();

      await tester.tap(
        find.byKey(EmojiFace.canvasKeyFor(EmojiChoice.neutral)),
      );
      await tester.pump();

      expect(find.byType(ThankYouCard), findsOneWidget);
      expect(submitter.calls, [EmojiChoice.neutral]);

      // Let the thank-you → prompt timer complete so no timer is left pending.
      await tester.pump(const Duration(seconds: 2, milliseconds: 1));
    });
  });
}
