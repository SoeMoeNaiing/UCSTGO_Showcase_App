import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/feedback.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/queued_feedback.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/usecases/submit_feedback.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/controllers/feedback_controller.dart';

class _FakeDeviceIds implements DeviceIdReader {
  @override
  Future<String> read() async => 'device-42';
}

class _FakeCooldown implements FeedbackCooldownStarter {
  int starts = 0;

  @override
  Future<void> start() async {
    starts++;
  }
}

class _FakeRepository implements FeedbackRepository {
  SubmissionResult result = const SubmissionAccepted(SyncStatus.synced);
  final submissions = <Feedback>[];

  @override
  Future<SubmissionResult> submit(Feedback feedback) async {
    submissions.add(feedback);
    return result;
  }

  @override
  Future<List<QueuedFeedback>> pending({int limit = 50}) =>
      throw UnimplementedError();

  @override
  Stream<int> watchPendingCount() => throw UnimplementedError();

  @override
  Future<void> applySyncStatus(
    String clientId,
    SyncStatus status, {
    DateTime? nextRetryAt,
  }) => throw UnimplementedError();
}

/// Iteration 21 — wiring gate: drives the **real** `SubmitFeedback` through
/// the controller with only repository/device/cooldown ports faked. Proves
/// the I20 seam swap needs no controller changes.
void main() {
  late _FakeRepository repository;
  late _FakeCooldown cooldown;
  late ProviderContainer container;
  late FeedbackController controller;

  void build({String clientId = 'client-1'}) {
    repository = _FakeRepository();
    cooldown = _FakeCooldown();
    final useCase = SubmitFeedback(
      repository: repository,
      deviceIds: _FakeDeviceIds(),
      cooldown: cooldown,
      newClientId: () => clientId,
      now: () => DateTime.utc(2026, 11, 19, 10),
    );
    container = ProviderContainer(
      overrides: [feedbackSubmitterProvider.overrideWith((ref) => useCase)],
    );
    addTearDown(container.dispose);
    controller = container.read(feedbackControllerProvider.notifier);
  }

  group('FeedbackController ↔ SubmitFeedback (§10.6)', () {
    test('success reaches the screen and starts the cooldown', () async {
      build();

      await controller.select(EmojiChoice.satisfied);

      expect(
        container.read(feedbackControllerProvider),
        FeedbackSuccess(EmojiChoice.satisfied),
      );
      expect(repository.submissions, hasLength(1));
      expect(cooldown.starts, 1);
    });

    test('a 429 produces the cooldown state and starts the timer', () async {
      build();
      repository.result = const SubmissionRefused(
        SyncStatus.rejected,
        'rate limited',
      );

      await controller.select(EmojiChoice.satisfied);

      final state = container.read(feedbackControllerProvider);
      expect(state, isA<FeedbackCooldown>());
      expect((state as FeedbackCooldown).message, contains('wait'));
      expect(cooldown.starts, 1);
    });

    test('a validation error uses the use case copy, not generic text',
        () async {
      build(clientId: '');

      await controller.select(EmojiChoice.satisfied);

      final state = container.read(feedbackControllerProvider);
      expect(state, isA<FeedbackError>());
      expect((state as FeedbackError).message, contains("couldn't prepare"));
      expect(repository.submissions, isEmpty);
    });

    test('offline pending still shows success', () async {
      build();
      repository.result = const SubmissionAccepted(SyncStatus.pending);

      await controller.select(EmojiChoice.neutral);

      expect(
        container.read(feedbackControllerProvider),
        FeedbackSuccess(EmojiChoice.neutral),
      );
    });
  });
}
