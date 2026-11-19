import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/models/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/models/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/repositories/feedback_remote_datasource.dart';
import 'package:ucstgo_showcase_flutter_app/repositories/feedback_model.dart';
import 'package:ucstgo_showcase_flutter_app/models/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/models/feedback.dart';
import 'package:ucstgo_showcase_flutter_app/models/queued_feedback.dart';
import 'package:ucstgo_showcase_flutter_app/repositories/feedback_repository.dart';
import 'package:ucstgo_showcase_flutter_app/services/sync_service.dart';

typedef _AppliedStatus = ({
  String clientId,
  SyncStatus status,
  DateTime? nextRetryAt,
});

class _QueueRow {
  _QueueRow(this.feedback, {this.attempts = 0, this.nextRetryAt});

  final Feedback feedback;
  int attempts;
  DateTime? nextRetryAt;
}

/// In-memory queue that mirrors the real repository's due-row semantics.
class _FakeQueue implements FeedbackRepository {
  _FakeQueue({DateTime Function()? now}) : now = now ?? DateTime.now;

  final DateTime Function() now;
  final rows = <_QueueRow>[];
  final applied = <_AppliedStatus>[];
  final _counts = StreamController<int>.broadcast();

  int pendingCalls = 0;

  void add(
    String clientId, {
    int attempts = 0,
    DateTime? nextRetryAt,
    String deviceId = 'device-1',
  }) {
    rows.add(
      _QueueRow(
        Feedback(
          clientId: clientId,
          deviceId: deviceId,
          emojiChoice: EmojiChoice.neutral,
          createdAt: DateTime.utc(2026, 11, 18, 12)
              .add(Duration(minutes: rows.length)),
        ),
        attempts: attempts,
        nextRetryAt: nextRetryAt,
      ),
    );
    _counts.add(rows.length);
  }

  @override
  Future<SubmissionResult> submit(Feedback feedback) =>
      throw UnimplementedError('SyncService must not re-insert submissions');

  @override
  Future<List<QueuedFeedback>> pending({int limit = 50}) async {
    pendingCalls++;
    final current = now().toUtc();
    return rows
        .where(
          (row) =>
              row.nextRetryAt == null || !row.nextRetryAt!.isAfter(current),
        )
        .take(limit)
        .map(
          (row) => QueuedFeedback(
            feedback: row.feedback,
            attempts: row.attempts,
          ),
        )
        .toList();
  }

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

    final index = rows.indexWhere((row) => row.feedback.clientId == clientId);
    if (index < 0) {
      return;
    }

    switch (status) {
      case SyncStatus.pending:
        if (nextRetryAt != null) {
          rows[index]
            ..attempts += 1
            ..nextRetryAt = nextRetryAt;
        }
      case SyncStatus.synced:
      case SyncStatus.rejected:
      case SyncStatus.failedPermanent:
        rows.removeAt(index);
    }
    _counts.add(rows.length);
  }

  @override
  Stream<int> watchPendingCount() => _counts.stream;

  Future<void> close() => _counts.close();
}

class _FakeRemote implements FeedbackRemoteDataSource {
  RemoteOutcome outcome = RemoteOutcome.success;
  Object? error;
  Completer<void>? gate;
  final calls = <FeedbackModel>[];
  int _inFlight = 0;
  int maxInFlight = 0;

  @override
  Future<RemoteOutcome> submit(FeedbackModel payload) async {
    calls.add(payload);
    _inFlight++;
    if (_inFlight > maxInFlight) {
      maxInFlight = _inFlight;
    }

    try {
      final blocker = gate;
      if (blocker != null) {
        await blocker.future;
      }
      // Yield so accidental parallel calls would be visible in maxInFlight.
      await Future<void>.delayed(Duration.zero);
      final failure = error;
      if (failure != null) {
        throw failure;
      }
      return outcome;
    } finally {
      _inFlight--;
    }
  }
}

/// Iteration 16 — SyncService gate (PROJECT_PROCESS.md §6.4, §6.6, §13).
///
/// The full outcome matrix, the six-step backoff ladder, the retry cap, and
/// trigger coalescing — all against fakes, with no network or real waiting.
void main() {
  late DateTime now;
  late _FakeQueue queue;
  late _FakeRemote remote;
  late SyncService service;

  setUp(() {
    now = DateTime.utc(2026, 11, 18, 12);
    queue = _FakeQueue(now: () => now);
    remote = _FakeRemote();
    service = SyncService(
      queue: queue,
      remote: remote,
      now: () => now,
    );
  });

  tearDown(() => queue.close());

  void expectScheduled({required int firstDelaySeconds}) {
    final applied = queue.applied.single;
    expect(applied.status, SyncStatus.pending);
    expect(applied.nextRetryAt, now.add(Duration(seconds: firstDelaySeconds)));
    expect(queue.rows, hasLength(1));
    expect(queue.rows.single.attempts, 1);
  }

  group('SyncService (§6.4, §6.6, §13)', () {
    test('an empty queue is a no-op', () async {
      await service.syncAll();

      expect(queue.pendingCalls, 1);
      expect(remote.calls, isEmpty);
      expect(queue.applied, isEmpty);
    });

    test('drains serially in FIFO order', () async {
      queue.add('a');
      queue.add('b');
      queue.add('c');

      await service.syncAll();

      expect(
        remote.calls.map((payload) => payload.clientId),
        ['a', 'b', 'c'],
      );
      expect(remote.maxInFlight, 1, reason: 'one upload at a time');
      expect(queue.rows, isEmpty);
      expect(
        queue.applied.map((entry) => entry.status),
        everyElement(SyncStatus.synced),
      );
    });

    test('success marks synced and removes the row', () async {
      remote.outcome = RemoteOutcome.success;
      queue.add('a');

      await service.syncAll();

      expect(queue.applied.single.status, SyncStatus.synced);
      expect(queue.applied.single.nextRetryAt, isNull);
      expect(queue.rows, isEmpty);
      expect(remote.calls.single.toJson(), {
        'client_id': 'a',
        'device_id': 'device-1',
        'emoji_choice': 'neutral',
      });
    });

    test('429 marks rejected and removes the row (terminal)', () async {
      remote.outcome = RemoteOutcome.rejected;
      queue.add('a');

      await service.syncAll();

      expect(queue.applied.single.status, SyncStatus.rejected);
      expect(queue.rows, isEmpty);
    });

    test('400 marks failed_permanent and removes the row', () async {
      remote.outcome = RemoteOutcome.invalid;
      queue.add('a');

      await service.syncAll();

      expect(queue.applied.single.status, SyncStatus.failedPermanent);
      expect(queue.rows, isEmpty);
    });

    test('5xx schedules the first retry at +2s', () async {
      remote.outcome = RemoteOutcome.serverError;
      queue.add('a');

      await service.syncAll();

      expectScheduled(firstDelaySeconds: 2);
      expect(remote.calls, hasLength(1));
    });

    test('network failure schedules the first retry at +2s', () async {
      remote.outcome = RemoteOutcome.networkFailure;
      queue.add('a');

      await service.syncAll();

      expectScheduled(firstDelaySeconds: 2);
      expect(remote.calls, hasLength(1));
    });

    test('a throwing remote is treated as a network failure', () async {
      remote.error = Exception('socket exploded');
      queue.add('a');

      await service.syncAll();

      expectScheduled(firstDelaySeconds: 2);
      expect(queue.rows.single.attempts, 1);
    });

    test('backoff follows 2→4→8→16→32→60s, then fails permanently',
        () async {
      remote.outcome = RemoteOutcome.networkFailure;
      queue.add('a');
      const seconds = [2, 4, 8, 16, 32, 60];

      for (var attempt = 0; attempt < seconds.length; attempt++) {
        await service.syncAll();

        final applied = queue.applied.last;
        expect(
          applied.status,
          SyncStatus.pending,
          reason: 'retry ${attempt + 1} must stay pending',
        );
        expect(
          applied.nextRetryAt,
          now.add(Duration(seconds: seconds[attempt])),
          reason: 'retry ${attempt + 1} delay',
        );
        expect(queue.rows.single.attempts, attempt + 1);

        expect(
          await queue.pending(),
          isEmpty,
          reason: 'row is not due before its deadline',
        );

        now = now.add(Duration(seconds: seconds[attempt]));
        expect(
          await queue.pending(),
          hasLength(1),
          reason: 'row is due at its deadline',
        );
      }

      await service.syncAll(); // the seventh upload exhausts six retries

      expect(queue.applied.last.status, SyncStatus.failedPermanent);
      expect(queue.rows, isEmpty);
      expect(remote.calls, hasLength(7));
    });

    test('a row with six recorded retries fails permanently', () async {
      remote.outcome = RemoteOutcome.serverError;
      queue.add('a', attempts: 6);

      await service.syncAll();

      expect(queue.applied.single.status, SyncStatus.failedPermanent);
      expect(queue.applied.single.nextRetryAt, isNull);
      expect(queue.rows, isEmpty);
    });

    test('two concurrent syncAll() calls share one drain', () async {
      queue.add('a');
      queue.add('b');
      remote.gate = Completer<void>();

      final first = service.syncAll();
      final second = service.syncAll();
      expect(identical(first, second), isTrue);

      await pumpEventQueue();
      expect(remote.calls, hasLength(1));

      remote.gate!.complete();
      await Future.wait([first, second]);

      expect(
        remote.calls.map((payload) => payload.clientId),
        ['a', 'b'],
      );
      expect(queue.rows, isEmpty);
    });

    test('loops until the queue is empty when the batch limit is smaller',
        () async {
      queue.add('a');
      queue.add('b');
      queue.add('c');
      final smallBatch = SyncService(
        queue: queue,
        remote: remote,
        now: () => now,
        batchSize: 2,
      );

      await smallBatch.syncAll();

      expect(remote.calls, hasLength(3));
      expect(queue.rows, isEmpty);
      expect(queue.pendingCalls, 3, reason: '2 + 1 + 0 rows per query');
    });

    test('pendingCount forwards the live queue count', () async {
      final counts = <int>[];
      final subscription = service.pendingCount.listen(counts.add);
      addTearDown(subscription.cancel);

      queue.add('a');
      queue.add('b');
      await pumpEventQueue();
      expect(counts, [1, 2]);

      await queue.applySyncStatus('a', SyncStatus.synced);
      await pumpEventQueue();
      expect(counts, [1, 2, 1]);
    });
  });
}
