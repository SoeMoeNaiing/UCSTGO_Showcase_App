import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/entities/rating.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/repositories/rating_repository.dart';

/// Minimal in-memory implementation proving the interface is *implementable*
/// exactly as designed (compile-time contract test, PROJECT_PROCESS.md §8.1.4).
class _FakeRatingRepository implements RatingRepository {
  SyncStatus nextSubmitStatus = SyncStatus.pending;
  final appliedStatuses = <String, SyncStatus>{};
  final queued = <Rating>[];

  @override
  Future<SubmissionResult> submit(Rating rating) async {
    queued.add(rating);
    return SubmissionAccepted(nextSubmitStatus);
  }

  @override
  Future<List<Rating>> pending({int limit = 50}) async =>
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

/// Iteration 8 — RatingRepository contract (mirrors feedback, §6.4).
void main() {
  Rating buildRating() => Rating(
        clientId: '0c2a4d7e-1b2c-4d5e-8f90-112233445566',
        deviceId: 'device-0001',
        projectId: 'project-07',
        score: 5,
        createdAt: DateTime.utc(2026, 11, 18, 12, 30),
      );

  test('a fake implements the RatingRepository contract end-to-end', () async {
    final RatingRepository repository = _FakeRatingRepository();
    final rating = buildRating();

    final result = await repository.submit(rating);

    expect(result, isA<SubmissionAccepted>());
    expect(result.status, SyncStatus.pending);

    final pending = await repository.pending();
    expect(pending, hasLength(1));
    expect(pending.single, rating);

    await repository.applySyncStatus(
      rating.clientId,
      SyncStatus.failedPermanent,
    );

    expect(
      (repository as _FakeRatingRepository).appliedStatuses[rating.clientId],
      SyncStatus.failedPermanent,
    );
  });

  test('limit is honoured by the pending surface', () async {
    final repository = _FakeRatingRepository();
    for (var i = 0; i < 3; i++) {
      await repository.submit(buildRating());
    }

    expect(await repository.pending(limit: 2), hasLength(2));
  });
}
