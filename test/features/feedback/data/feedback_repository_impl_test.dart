import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/data/datasources/feedback_local_datasource.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/data/datasources/feedback_remote_datasource.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/data/local/app_database.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/data/models/feedback_model.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/data/repositories/feedback_repository_impl.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/feedback.dart';
import 'package:ucstgo_showcase_flutter_app/services/device_id_service.dart';

/// Fake remote with a programmable outcome and call log.
class _FakeRemote implements FeedbackRemoteDataSource {
  RemoteOutcome outcome = RemoteOutcome.success;
  Object? error;
  final calls = <FeedbackModel>[];
  Future<void> Function(FeedbackModel payload)? onCall;

  @override
  Future<RemoteOutcome> submit(FeedbackModel payload) async {
    calls.add(payload);
    await onCall?.call(payload);
    final failure = error;
    if (failure != null) throw failure;
    return outcome;
  }
}

/// Mocktail remote used to pin the exact payload crossing the seam.
class _MockRemote extends Mock implements FeedbackRemoteDataSource {}

/// Empty identity storage standing in for a first launch.
class _FakeDeviceIdStorage implements DeviceIdStorage {
  String? value;
  int writes = 0;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String newValue) async {
    value = newValue;
    writes++;
  }
}

/// Iteration 11 — FeedbackRepositoryImpl gate (PROJECT_PROCESS.md §6.4, §6.6).
///
/// Proves the local-first contract with fakes: the row is durable before the
/// network is consulted, only online + non-throwing paths call remote, and
/// every outcome lands in the documented terminal/pending state.
void main() {
  late AppDatabase db;
  late FeedbackLocalDataSource local;
  late _FakeRemote remote;
  late FeedbackRepositoryImpl repository;
  late DateTime now;
  late bool online;

  setUpAll(() {
    registerFallbackValue(
      const FeedbackModel(
        clientId: 'fallback-client',
        deviceId: 'fallback-device',
        emojiChoice: EmojiChoice.neutral,
      ),
    );
  });

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    now = DateTime.utc(2026, 11, 18, 12);
    local = FeedbackLocalDataSource(db, now: () => now);
    remote = _FakeRemote();
    online = true;
    repository = FeedbackRepositoryImpl(
      local: local,
      remote: remote,
      isOnline: () async => online,
    );
  });

  tearDown(() async {
    await db.close();
  });

  Feedback build({
    String client = 'client-1',
    String device = 'device-1',
    DateTime? at,
  }) {
    return Feedback(
      clientId: client,
      deviceId: device,
      emojiChoice: EmojiChoice.neutral,
      createdAt: at ?? now,
    );
  }

  Future<PendingFeedbackData> row(String clientId) async {
    return (db.select(db.pendingFeedback)
          ..where((table) => table.clientId.equals(clientId)))
        .getSingle();
  }

  group('FeedbackRepositoryImpl (§6.4, §6.6)', () {
    test('the local write happens before the remote call', () async {
      PendingFeedbackData? rowDuringUpload;
      remote.onCall = (payload) async {
        rowDuringUpload = await (db.select(db.pendingFeedback)
              ..where((table) => table.clientId.equals(payload.clientId)))
            .getSingleOrNull();
      };

      await repository.submit(build());

      expect(rowDuringUpload, isNotNull);
      expect(
        rowDuringUpload!.syncStatus,
        SyncStatus.pending.wireValue,
        reason: 'durable pending row must exist before the network call',
      );
    });

    test('offline: pending result, row durable, remote never called', () async {
      online = false;

      final result = await repository.submit(build());

      expect(result, isA<SubmissionAccepted>());
      expect(result.status, SyncStatus.pending);
      expect(remote.calls, isEmpty);
      expect(
        (await row('client-1')).syncStatus,
        SyncStatus.pending.wireValue,
      );
    });

    test('online success: row synced and result accepted', () async {
      remote.outcome = RemoteOutcome.success;

      final result = await repository.submit(build());

      expect(result, isA<SubmissionAccepted>());
      expect(result.status, SyncStatus.synced);
      expect((await row('client-1')).syncStatus, SyncStatus.synced.wireValue);
      expect(await repository.pending(), isEmpty);
    });

    test('network failure: accepted pending, row stays retryable', () async {
      remote.outcome = RemoteOutcome.networkFailure;

      final result = await repository.submit(build());

      expect(result, isA<SubmissionAccepted>());
      expect(result.status, SyncStatus.pending);
      expect((await row('client-1')).syncStatus, SyncStatus.pending.wireValue);
      expect(await repository.pending(), hasLength(1));
    });

    test('a throwing remote cannot break the visitor action', () async {
      remote.error = Exception('socket exploded');

      final result = await repository.submit(build());

      expect(result, isA<SubmissionAccepted>());
      expect(result.status, SyncStatus.pending);
      expect((await row('client-1')).syncStatus, SyncStatus.pending.wireValue);
    });

    test('429: refused + row rejected (terminal, not pending)', () async {
      remote.outcome = RemoteOutcome.rejected;

      final result = await repository.submit(build());

      expect(result, isA<SubmissionRefused>());
      expect(result.status, SyncStatus.rejected);
      expect(
        (result as SubmissionRefused).reason,
        contains('rate limited'),
      );
      expect((await row('client-1')).syncStatus, SyncStatus.rejected.wireValue);
      expect(await repository.pending(), isEmpty);
    });

    test('400: refused + row failed_permanent', () async {
      remote.outcome = RemoteOutcome.invalid;

      final result = await repository.submit(build());

      expect(result, isA<SubmissionRefused>());
      expect(result.status, SyncStatus.failedPermanent);
      expect((await row('client-1')).syncStatus, SyncStatus.failedPermanent.wireValue);
      expect(await repository.pending(), isEmpty);
    });

    test('5xx: accepted pending for backoff retry', () async {
      remote.outcome = RemoteOutcome.serverError;

      final result = await repository.submit(build());

      expect(result, isA<SubmissionAccepted>());
      expect(result.status, SyncStatus.pending);
      expect((await row('client-1')).syncStatus, SyncStatus.pending.wireValue);
    });

    test('applySyncStatus pending schedules the backoff deadline', () async {
      online = false;
      await repository.submit(build());
      final retryAt = now.add(const Duration(seconds: 30));

      await repository.applySyncStatus(
        'client-1',
        SyncStatus.pending,
        nextRetryAt: retryAt,
      );

      expect(await repository.pending(), isEmpty);
      expect((await row('client-1')).attempts, 1);

      now = retryAt;
      expect((await repository.pending()).single.feedback.clientId, 'client-1');
    });

    test('applySyncStatus delegates terminal states', () async {
      await repository.submit(build(client: 'synced-1'));
      await repository.submit(build(client: 'rejected-1'));
      await repository.submit(build(client: 'failed-1'));

      await repository.applySyncStatus('synced-1', SyncStatus.synced);
      await repository.applySyncStatus('rejected-1', SyncStatus.rejected);
      await repository.applySyncStatus(
        'failed-1',
        SyncStatus.failedPermanent,
      );

      expect((await row('synced-1')).syncStatus, SyncStatus.synced.wireValue);
      expect(
        (await row('rejected-1')).syncStatus,
        SyncStatus.rejected.wireValue,
      );
      expect(
        (await row('failed-1')).syncStatus,
        SyncStatus.failedPermanent.wireValue,
      );
      expect(await repository.pending(), isEmpty);
    });

    test('pending(limit) is forwarded to the queue', () async {
      online = false;
      for (var minute = 0; minute < 3; minute++) {
        await repository.submit(
          build(
            client: 'client-$minute',
            at: now.add(Duration(minutes: minute)),
          ),
        );
      }

      expect(await repository.pending(limit: 2), hasLength(2));
    });

    test('the remote seam receives the exact §6.2 wire payload', () async {
      final mockRemote = _MockRemote();
      when(() => mockRemote.submit(any()))
          .thenAnswer((_) async => RemoteOutcome.success);
      final wired = FeedbackRepositoryImpl(
        local: local,
        remote: mockRemote,
        isOnline: () async => true,
      );

      await wired.submit(build());

      final payload = verify(() => mockRemote.submit(captureAny()))
          .captured
          .single as FeedbackModel;
      expect(payload.toJson(), {
        'client_id': 'client-1',
        'device_id': 'device-1',
        'emoji_choice': 'neutral',
      });
    });

    test('first run: empty identity storage is filled before the row is saved',
        () async {
      final storage = _FakeDeviceIdStorage();
      final deviceIds = DeviceIdService(storage: storage);
      final deviceId = await deviceIds.getOrCreate();

      await repository.submit(build(device: deviceId));

      final saved = await row('client-1');
      expect(saved.deviceId, deviceId);
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(saved.deviceId),
        isTrue,
        reason: 'device ids are UUID v4',
      );
      expect(storage.writes, 1, reason: 'generated exactly once');
      expect(remote.calls.single.deviceId, deviceId);
    });

    test('watchPendingCount follows the live pending total', () async {
      online = false;
      await repository.submit(build(client: 'a'));
      await repository.submit(
        build(client: 'b', at: now.add(const Duration(minutes: 1))),
      );

      final counts = <int>[];
      final subscription = repository.watchPendingCount().listen(counts.add);
      addTearDown(subscription.cancel);

      await pumpEventQueue();
      expect(counts.last, 2);

      await repository.applySyncStatus('a', SyncStatus.synced);
      await pumpEventQueue();
      expect(counts.last, 1);
    });
  });
}
