import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/feedback.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/repositories/feedback_repository.dart';

/// Minimal in-memory implementation proving the interface is *implementable*
/// exactly as designed (compile-time contract test, PROJECT_PROCESS.md §8.1.4).
class _FakeFeedbackRepository implements FeedbackRepository {
  SyncStatus nextSubmitStatus = SyncStatus.pending;
  final appliedStatuses = <String, SyncStatus>{};
  final queued = <Feedback>[];

  @override
  Future<SubmissionResult> submit(Feedback feedback) async {
    queued.add(feedback);
    return SubmissionAccepted(nextSubmitStatus);
  }

  @override
  Future<List<Feedback>> pending({int limit = 50}) async =>
      queued.take(limit).toList();

  @override
  Future<void> applySyncStatus(
    String clientId,
    SyncStatus status, {
    DateTime? nextRetryAt,
  }) async {
    appliedStatuses[clientId] = status;
  }
}

/// Iteration 8 — FeedbackRepository contract (§4.2, §6.4, §6.6).
void main() {
  Feedback buildFeedback() => Feedback(
        clientId: '8f14e45f-ceea-467a-8f7e-1b2c3d4e5f60',
        deviceId: 'device-0001',
        emojiChoice: EmojiChoice.neutral,
        createdAt: DateTime.utc(2026, 11, 18, 12),
      );

  test('a fake implements the FeedbackRepository contract end-to-end', () async {
    final FeedbackRepository repository = _FakeFeedbackRepository();
    final feedback = buildFeedback();

    final result = await repository.submit(feedback);

    expect(result, isA<SubmissionAccepted>());
    expect(result.status, SyncStatus.pending);

    final pending = await repository.pending();
    expect(pending, hasLength(1));
    expect(pending.single, feedback);

    await repository.applySyncStatus(
      feedback.clientId,
      SyncStatus.rejected,
    );

    expect(
      (repository as _FakeFeedbackRepository).appliedStatuses[feedback.clientId],
      SyncStatus.rejected,
    );
  });

  test('limit is honoured by the pending surface', () async {
    final repository = _FakeFeedbackRepository();
    for (var i = 0; i < 3; i++) {
      await repository.submit(buildFeedback());
    }

    expect(await repository.pending(limit: 2), hasLength(2));
  });
}
