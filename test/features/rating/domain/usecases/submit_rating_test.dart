import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/identity_ports.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/entities/queued_rating.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/entities/rating.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/repositories/rating_repository.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/usecases/submit_rating.dart';

class _FakeDeviceIds implements DeviceIdReader {
  String value = 'device-42';

  @override
  Future<String> read() async => value;
}

class _FakeCooldown implements RatingCooldownStarter {
  int starts = 0;

  @override
  Future<void> start() async => starts++;
}

class _FakeRepository implements RatingRepository {
  SubmissionResult result = const SubmissionAccepted(SyncStatus.pending);
  final submissions = <Rating>[];

  @override
  Future<SubmissionResult> submit(Rating rating) async {
    submissions.add(rating);
    return result;
  }

  @override
  Future<List<QueuedRating>> pending({int limit = 50}) =>
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

/// Iteration 28 — SubmitRating gate (§6.3, §6.5, §7).
void main() {
  late _FakeRepository repository;
  late _FakeDeviceIds deviceIds;
  late _FakeCooldown cooldown;
  late DateTime now;
  late SubmitRating useCase;
  late int counter;

  SubmitRating build({String Function()? clientId}) => SubmitRating(
        repository: repository,
        deviceIds: deviceIds,
        cooldown: cooldown,
        newClientId: clientId ?? () => 'client-${++counter}',
        now: () => now,
      );

  setUp(() {
    repository = _FakeRepository();
    deviceIds = _FakeDeviceIds();
    cooldown = _FakeCooldown();
    now = DateTime(2026, 11, 19, 10);
    counter = 0;
    useCase = build();
  });

  group('SubmitRating (§10.7)', () {
    test('happy path builds the entity from injected ports', () async {
      final result = await useCase.submit(
        projectId: 'campus-navigator',
        score: 4,
      );

      expect(result, isA<SubmissionAccepted>());
      final rating = repository.submissions.single;
      expect(rating.clientId, 'client-1');
      expect(rating.deviceId, 'device-42');
      expect(rating.projectId, 'campus-navigator');
      expect(rating.score, 4);
      expect(rating.createdAt, now.toUtc());
      expect(rating.createdAt.isUtc, isTrue);
      expect(cooldown.starts, 1);
    });

    test('offline (pending) acceptance still starts the cooldown', () async {
      repository.result = const SubmissionAccepted(SyncStatus.pending);

      final result = await useCase.submit(projectId: 'p', score: 1);

      expect(result, const SubmissionAccepted(SyncStatus.pending));
      expect(cooldown.starts, 1);
    });

    test('429 starts the cooldown; 400 does not', () async {
      repository.result = const SubmissionRefused(
        SyncStatus.rejected,
        'rate limited',
      );
      await useCase.submit(projectId: 'p', score: 2);
      expect(cooldown.starts, 1);

      repository.result = const SubmissionRefused(
        SyncStatus.failedPermanent,
        'bad payload',
      );
      await useCase.submit(projectId: 'p', score: 2);
      expect(cooldown.starts, 1, reason: 'a 400 is not a rate limit');
    });

    test('invalid input is a validation error, never a submission', () async {
      await expectLater(
        useCase.submit(projectId: '', score: 3),
        throwsA(isA<RatingValidationException>()),
      );
      await expectLater(
        useCase.submit(projectId: 'p', score: 6),
        throwsA(isA<RatingValidationException>()),
      );
      expect(repository.submissions, isEmpty);
      expect(cooldown.starts, 0);
    });

    test('missing generated identity is a validation error', () async {
      useCase = build(clientId: () => ' ');

      await expectLater(
        useCase.submit(projectId: 'p', score: 3),
        throwsA(isA<RatingValidationException>()),
      );
      expect(repository.submissions, isEmpty);
    });
  });
}
