import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/data/datasources/feedback_remote_datasource.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/data/models/feedback_model.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/feedback.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/queued_feedback.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/data/datasources/rating_remote_datasource.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/data/models/rating_model.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/entities/queued_rating.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/entities/rating.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/repositories/rating_repository.dart';
import 'package:ucstgo_showcase_flutter_app/services/sync_service.dart';

typedef _Applied = ({
  String clientId,
  SyncStatus status,
  DateTime? nextRetryAt,
});

class _RatingRow {
  _RatingRow(this.rating, {this.attempts = 0, this.nextRetryAt});

  final Rating rating;
  int attempts;
  DateTime? nextRetryAt;
}

class _RatingQueue implements RatingRepository {
  _RatingQueue({DateTime Function()? now}) : now = now ?? DateTime.now;

  final DateTime Function() now;
  final rows = <_RatingRow>[];
  final applied = <_Applied>[];
  final _counts = StreamController<int>.broadcast();

  void add(String clientId, {int attempts = 0, DateTime? nextRetryAt}) {
    rows.add(
      _RatingRow(
        Rating(
          clientId: clientId,
          deviceId: 'device-1',
          projectId: 'campus-navigator',
          score: 4,
          createdAt: DateTime.utc(2026, 11, 19, 12),
        ),
        attempts: attempts,
        nextRetryAt: nextRetryAt,
      ),
    );
  }

  @override
  Future<SubmissionResult> submit(Rating rating) => throw UnimplementedError();

  @override
  Future<List<QueuedRating>> pending({int limit = 50}) async {
    final current = now().toUtc();
    return rows
        .where(
          (row) =>
              row.nextRetryAt == null || !row.nextRetryAt!.isAfter(current),
        )
        .map(
          (row) => QueuedRating(
            rating: row.rating,
            attempts: row.attempts,
          ),
        )
        .toList();
  }

  @override
  Stream<int> watchPendingCount() => _counts.stream;

  @override
  Future<void> applySyncStatus(
    String clientId,
    SyncStatus status, {
    DateTime? nextRetryAt,
  }) async {
    applied.add((
      clientId: clientId,
      status: status,
      nextRetryAt: nextRetryAt,
    ));
    final index = rows.indexWhere((row) => row.rating.clientId == clientId);
    if (index < 0) {
      return;
    }
    if (status == SyncStatus.pending && nextRetryAt != null) {
      rows[index]
        ..attempts += 1
        ..nextRetryAt = nextRetryAt;
    } else {
      rows.removeAt(index);
    }
  }

  Future<void> close() => _counts.close();
}

class _RatingRemote implements RatingRemoteDataSource {
  RemoteOutcome outcome = RemoteOutcome.success;
  final calls = <RatingModel>[];

  @override
  Future<RemoteOutcome> submit(RatingModel payload) async {
    calls.add(payload);
    return outcome;
  }
}

class _EmptyFeedbackQueue implements FeedbackRepository {
  @override
  Future<SubmissionResult> submit(Feedback feedback) => throw UnimplementedError();

  @override
  Future<List<QueuedFeedback>> pending({int limit = 50}) async => [];

  @override
  Stream<int> watchPendingCount() => const Stream.empty();

  @override
  Future<void> applySyncStatus(
    String clientId,
    SyncStatus status, {
    DateTime? nextRetryAt,
  }) => throw UnimplementedError();
}

class _FeedbackRemote implements FeedbackRemoteDataSource {
  final calls = <FeedbackModel>[];

  @override
  Future<RemoteOutcome> submit(FeedbackModel payload) async {
    calls.add(payload);
    return RemoteOutcome.success;
  }
}

/// Iteration 28 — both queues ride the same SyncService (§6.4, §6.6, §13).
void main() {
  late DateTime now;
  late _RatingQueue ratings;
  late _RatingRemote ratingRemote;
  late _EmptyFeedbackQueue feedback;
  late _FeedbackRemote feedbackRemote;
  late SyncService service;

  setUp(() {
    now = DateTime.utc(2026, 11, 19, 12);
    ratings = _RatingQueue(now: () => now);
    ratingRemote = _RatingRemote();
    feedback = _EmptyFeedbackQueue();
    feedbackRemote = _FeedbackRemote();
    service = SyncService(
      queue: feedback,
      remote: feedbackRemote,
      ratingQueue: ratings,
      ratingRemote: ratingRemote,
      now: () => now,
    );
  });

  tearDown(() => ratings.close());

  group('SyncService ↔ ratings (I28)', () {
    test('drains a rating row through its own seam', () async {
      ratings.add('r1');

      await service.syncAll();

      expect(ratingRemote.calls.single.toJson(), {
        'client_id': 'r1',
        'device_id': 'device-1',
        'project_id': 'campus-navigator',
        'score': 4,
      });
      expect(ratings.applied.single.status, SyncStatus.synced);
      expect(ratings.rows, isEmpty);
    });

    test('rating outcomes use the same matrix and backoff', () async {
      ratings.add('r1');
      ratingRemote.outcome = RemoteOutcome.rejected;
      await service.syncAll();
      expect(ratings.applied.single.status, SyncStatus.rejected);

      ratings.add('r2');
      ratingRemote.outcome = RemoteOutcome.serverError;
      await service.syncAll();
      expect(
        ratings.applied.last.nextRetryAt,
        now.add(const Duration(seconds: 2)),
      );
      expect(ratings.rows.single.attempts, 1);
    });

    test('a rating row with six retries fails permanently', () async {
      ratings.add('r1', attempts: 6);
      ratingRemote.outcome = RemoteOutcome.networkFailure;

      await service.syncAll();

      expect(ratings.applied.single.status, SyncStatus.failedPermanent);
      expect(ratings.rows, isEmpty);
    });

    test('rating seams are optional (I16 tests stay valid)', () async {
      final withoutRatings = SyncService(
        queue: feedback,
        remote: feedbackRemote,
        now: () => now,
      );
      ratings.add('r1');

      await withoutRatings.syncAll();

      expect(ratingRemote.calls, isEmpty);
      expect(ratings.applied, isEmpty);
    });
  });
}
