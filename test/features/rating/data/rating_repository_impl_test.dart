import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/remote_outcome.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/data/local/app_database.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/data/datasources/rating_local_datasource.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/data/datasources/rating_remote_datasource.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/data/models/rating_model.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/data/repositories/rating_repository_impl.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/entities/rating.dart';

class _FakeRemote implements RatingRemoteDataSource {
  RemoteOutcome outcome = RemoteOutcome.success;
  final calls = <RatingModel>[];

  @override
  Future<RemoteOutcome> submit(RatingModel payload) async {
    calls.add(payload);
    return outcome;
  }
}

/// Iteration 28 — RatingRepositoryImpl gate (§6.4, §6.6, Patch D).
void main() {
  late AppDatabase db;
  late RatingLocalDataSource local;
  late _FakeRemote remote;
  late RatingRepositoryImpl repository;
  late bool online;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    local = RatingLocalDataSource(db);
    remote = _FakeRemote();
    online = false;
    repository = RatingRepositoryImpl(
      local: local,
      remote: remote,
      isOnline: () async => online,
    );
  });

  tearDown(() async => db.close());

  Rating build() => Rating(
        clientId: 'client-1',
        deviceId: 'device-1',
        projectId: 'campus-navigator',
        score: 5,
        createdAt: DateTime.utc(2026, 11, 19, 10),
      );

  group('RatingRepositoryImpl (§6.4, §6.6)', () {
    test('offline: durable pending row, no upload, still accepted', () async {
      final result = await repository.submit(build());

      expect(result, const SubmissionAccepted(SyncStatus.pending));
      expect(remote.calls, isEmpty);
      expect((await local.pending()).single.rating, build());
    });

    test('online: exact wire payload crosses the seam and row is synced',
        () async {
      online = true;

      final result = await repository.submit(build());

      expect(result, const SubmissionAccepted(SyncStatus.synced));
      expect(remote.calls.single.toJson(), {
        'client_id': 'client-1',
        'device_id': 'device-1',
        'project_id': 'campus-navigator',
        'score': 5,
      });
      final row = (db.select(db.pendingRatings)
            ..where((table) => table.clientId.equals('client-1')))
          .getSingle();
      expect((await row).syncStatus, SyncStatus.synced.wireValue);
    });

    test('429 is a terminal rejection', () async {
      online = true;
      remote.outcome = RemoteOutcome.rejected;

      final result = await repository.submit(build());

      expect(
        result,
        const SubmissionRefused(SyncStatus.rejected, 'rate limited by the server'),
      );
    });

    test('400 is a terminal permanent failure', () async {
      online = true;
      remote.outcome = RemoteOutcome.invalid;

      final result = await repository.submit(build());

      expect(result.status, SyncStatus.failedPermanent);
    });

    test('5xx leaves the row pending for the sync engine', () async {
      online = true;
      remote.outcome = RemoteOutcome.serverError;

      final result = await repository.submit(build());

      expect(result, const SubmissionAccepted(SyncStatus.pending));
      expect((await local.pending()), hasLength(1));
    });
  });
}
