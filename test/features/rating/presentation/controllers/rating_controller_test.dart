import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/models/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/models/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/controllers/submit_rating.dart';
import 'package:ucstgo_showcase_flutter_app/controllers/rating_controller.dart';

class _FakeSubmitter implements RatingSubmitter {
  SubmissionResult result = const SubmissionAccepted(SyncStatus.pending);
  Object? error;
  final calls = <({String projectId, int score})>[];

  @override
  Future<SubmissionResult> submit({
    required String projectId,
    required int score,
  }) async {
    calls.add((projectId: projectId, score: score));
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return result;
  }
}

/// Iteration 28 — RatingController gate (§10.7, §2.1.7).
void main() {
  late _FakeSubmitter submitter;
  late ProviderContainer container;
  late RatingController controller;

  void build() {
    submitter = _FakeSubmitter();
    container = ProviderContainer(
      overrides: [ratingSubmitterProvider.overrideWith((ref) => submitter)],
    );
    addTearDown(container.dispose);
    controller = container.read(ratingControllerProvider.notifier);
  }

  group('RatingController (§10.7)', () {
    test('starts idle and reaches success', () async {
      build();
      expect(container.read(ratingControllerProvider), const RatingIdle());

      await controller.submit(projectId: 'p', score: 4);

      expect(
        container.read(ratingControllerProvider),
        const RatingSuccess(projectId: 'p', score: 4),
      );
      expect(submitter.calls, [(projectId: 'p', score: 4)]);
    });

    test('a second submission while submitting is ignored', () async {
      build();
      final first = controller.submit(projectId: 'p', score: 1);
      await controller.submit(projectId: 'other', score: 5);
      expect(submitter.calls, [(projectId: 'p', score: 1)]);
      await first;
    });

    test('429 maps to a cooldown message', () async {
      build();
      submitter.result = const SubmissionRefused(
        SyncStatus.rejected,
        'rate limited',
      );

      await controller.submit(projectId: 'p', score: 2);

      final state = container.read(ratingControllerProvider);
      expect(state, isA<RatingCooldown>());
      expect((state as RatingCooldown).message, contains('wait'));
    });

    test('400 and thrown errors map to user-facing errors', () async {
      build();
      submitter.result = const SubmissionRefused(
        SyncStatus.failedPermanent,
        'bad payload',
      );
      await controller.submit(projectId: 'p', score: 2);
      final firstError = container.read(ratingControllerProvider);
      expect(firstError, isA<RatingError>());
      expect(
        (firstError as RatingError).message,
        isNot(contains('bad payload')),
      );

      controller.reset();
      expect(container.read(ratingControllerProvider), const RatingIdle());

      submitter.error = Exception('socket exploded');
      await controller.submit(projectId: 'p', score: 2);
      final secondError = container.read(ratingControllerProvider);
      expect(secondError, isA<RatingError>());
      expect(
        (secondError as RatingError).message,
        isNot(contains('socket')),
      );
    });

    test('validation errors use the use-case message', () async {
      build();
      submitter.error = const RatingValidationException('bad rating');

      await controller.submit(projectId: 'p', score: 2);

      final state = container.read(ratingControllerProvider);
      expect(state, const RatingError('bad rating'));
    });

    test('success and cooldown stay locked until reset()', () async {
      build();
      await controller.submit(projectId: 'p', score: 3);
      await controller.submit(projectId: 'other', score: 5);
      expect(submitter.calls, hasLength(1));

      controller.reset();
      await controller.submit(projectId: 'other', score: 5);
      expect(submitter.calls, hasLength(2));
    });
  });
}
