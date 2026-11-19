import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/app.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/core/router/app_router.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/usecases/submit_feedback.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/controllers/feedback_controller.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/widgets/emoji_picker.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/widgets/rate_projects_prompt.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/widgets/thank_you_card.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/usecases/submit_rating.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/presentation/controllers/rating_controller.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/presentation/screens/rating_screen.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/presentation/widgets/rating_widget.dart';
import 'package:ucstgo_showcase_flutter_app/features/showcase/presentation/widgets/project_card.dart';
import 'package:ucstgo_showcase_flutter_app/features/showcase/presentation/widgets/project_carousel.dart';

class _FakeFeedbackSubmitter implements FeedbackSubmitter {
  @override
  Future<SubmissionResult> submit(EmojiChoice choice) async =>
      const SubmissionAccepted(SyncStatus.pending);
}

class _FakeSubmitter implements RatingSubmitter {
  SubmissionResult result = const SubmissionAccepted(SyncStatus.pending);
  final calls = <({String projectId, int score})>[];

  @override
  Future<SubmissionResult> submit({
    required String projectId,
    required int score,
  }) async {
    calls.add((projectId: projectId, score: score));
    return result;
  }
}

/// Iteration 29 — RatingScreen E2E (§10.7, milestone M5).
void main() {
  late _FakeSubmitter submitter;

  Widget host({String initialLocation = '/rating'}) {
    final router = createAppRouter(initialLocation: initialLocation);
    addTearDown(router.dispose);
    return ProviderScope(
      overrides: [
        ratingSubmitterProvider.overrideWith((ref) => submitter),
        feedbackSubmitterProvider.overrideWith(
          (ref) => _FakeFeedbackSubmitter(),
        ),
      ],
      child: KioskApp(router: router),
    );
  }

  setUp(() => submitter = _FakeSubmitter());

  Future<void> selectFirstProject(WidgetTester tester) async {
    // The selected view (card + stars + submit) is taller than 600px.
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ProjectCard).first);
    await tester.pumpAndSettle();
  }

  group('RatingScreen E2E (§10.7)', () {
    testWidgets('selecting a card reveals the stars', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      expect(find.byType(ProjectCarousel), findsOneWidget);
      expect(find.byType(RatingWidget), findsNothing);

      await tester.tap(find.byType(ProjectCard).first);
      await tester.pumpAndSettle();

      expect(find.byType(RatingWidget), findsOneWidget);
      expect(find.text('How would you rate it?'), findsOneWidget);
    });

    testWidgets('score + submit calls once and shows confirmation',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await selectFirstProject(tester);

        final submit = find.descendant(
        of: find.byKey(RatingScreen.submitKey),
        matching: find.byType(FilledButton),
      );
        expect(
          tester.widget<FilledButton>(submit).onPressed,
          isNull,
          reason: 'submit is disabled until a score is chosen',
        );

        await tester.tap(find.bySemanticsLabel('Rate 4 stars'));
        await tester.pumpAndSettle();
        expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

        await tester.tap(submit);
        await tester.pumpAndSettle();

        expect(submitter.calls, [
          (projectId: 'campus-navigator', score: 4),
        ]);
        expect(find.byKey(RatingScreen.confirmationKey), findsOneWidget);
        expect(find.text('Rating saved!'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('an offline pending result still confirms without crashing',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        submitter.result = const SubmissionAccepted(SyncStatus.pending);
        await selectFirstProject(tester);

        await tester.tap(find.bySemanticsLabel('Rate 1 stars'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byKey(RatingScreen.submitKey),
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(RatingScreen.confirmationKey), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('a 429 shows the cooldown and withholds Submit',
        (tester) async {
      final handle = tester.ensureSemantics();
      try {
        submitter.result = const SubmissionRefused(
          SyncStatus.rejected,
          'rate limited',
        );
        await selectFirstProject(tester);

        await tester.tap(find.bySemanticsLabel('Rate 3 stars'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byKey(RatingScreen.submitKey),
            matching: find.byType(FilledButton),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(RatingScreen.statusKey), findsOneWidget);
        expect(find.byType(RatingWidget), findsNothing);
        expect(find.byKey(RatingScreen.submitKey), findsNothing);

        await tester.tap(find.text('Done'));
        await tester.pumpAndSettle();
        expect(find.byType(ProjectCarousel), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('Yes on the feedback prompt navigates into the rating flow',
        (tester) async {
      await tester.pumpWidget(host(initialLocation: '/feedback'));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(EmojiFace.canvasKeyFor(EmojiChoice.satisfied)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ThankYouCard), findsOneWidget);

      await tester.pump(const Duration(seconds: 2, milliseconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(RateProjectsPrompt), findsOneWidget);

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(find.byType(RatingScreen), findsOneWidget);
      expect(find.byType(ProjectCarousel), findsOneWidget);
    });
  });
}
