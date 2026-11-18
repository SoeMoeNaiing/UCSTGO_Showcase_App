import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/services/connectivity_service.dart';
import 'package:ucstgo_showcase_flutter_app/services/sync_scheduler.dart';
import 'package:ucstgo_showcase_flutter_app/services/sync_service.dart';

/// Sync runner that models the real service's coalescing contract.
class _FakeSync implements SyncRunner {
  int triggers = 0;
  int executions = 0;
  Completer<void>? gate;
  Future<void>? _inFlight;

  @override
  Future<void> syncAll() {
    triggers++;
    return _inFlight ??= _run().whenComplete(() => _inFlight = null);
  }

  Future<void> _run() async {
    executions++;
    final blocker = gate;
    if (blocker != null) {
      await blocker.future;
    }
  }
}

class _FakeConnectivity implements ConnectivityStatus {
  _FakeConnectivity(this._online);

  bool _online;
  final _changes = StreamController<bool>.broadcast();

  @override
  bool get isOnline => _online;

  @override
  Stream<bool> get online => _changes.stream;

  @override
  Future<bool> start() async => _online;

  void emit(bool value) {
    _online = value;
    _changes.add(value);
  }

  Future<void> close() => _changes.close();
}

/// Iteration 17 — SyncScheduler triggers (PROJECT_PROCESS.md §6.4).
///
/// Proves each of the four triggers fires exactly one sweep, that offline
/// ticks are inert, that nudges debounce, and that overlapping triggers
/// collapse — the last piece of milestone M3.
void main() {
  late _FakeSync sync;
  late _FakeConnectivity connectivity;
  late SyncScheduler scheduler;

  void build({
    bool online = true,
    Duration interval = const Duration(minutes: 5),
    Duration nudge = const Duration(seconds: 1),
  }) {
    sync = _FakeSync();
    connectivity = _FakeConnectivity(online);
    scheduler = SyncScheduler(
      sync: sync,
      connectivity: connectivity,
      interval: interval,
      nudgeDelay: nudge,
    );
    addTearDown(() async {
      await scheduler.dispose();
      await connectivity.close();
    });
  }

  group('SyncScheduler (§6.4, §13)', () {
    test('app start sweeps once when online', () async {
      build();

      await scheduler.start();

      expect(sync.triggers, 1);
      expect(sync.executions, 1);
    });

    test('app start does not sweep while offline', () async {
      build(online: false);

      await scheduler.start();

      expect(sync.triggers, 0);
    });

    test('a connectivity rising edge triggers exactly one sweep', () async {
      build(online: false);
      await scheduler.start();
      expect(sync.triggers, 0);

      connectivity.emit(true);
      await pumpEventQueue();

      expect(sync.triggers, 1);
      expect(sync.executions, 1);
    });

    test('a falling edge does not trigger a sweep', () async {
      build();
      await scheduler.start();
      expect(sync.triggers, 1);

      connectivity.emit(false);
      await pumpEventQueue();

      expect(sync.triggers, 1);
    });

    test('offline: nudges and periodic ticks never start a sweep', () {
      fakeAsync((async) {
        build(online: false);
        scheduler.start();
        async.flushMicrotasks();
        expect(sync.triggers, 0);

        scheduler.notifyLocalWrite();
        async.elapse(const Duration(seconds: 2));
        expect(sync.triggers, 0, reason: 'the 1s nudge was skipped');

        async.elapse(const Duration(minutes: 5));
        expect(sync.triggers, 0, reason: 'the 5min tick was skipped');
      });
    });

    test('the periodic timer sweeps every five minutes', () {
      fakeAsync((async) {
        build();
        scheduler.start();
        async.flushMicrotasks();
        expect(sync.triggers, 1, reason: 'app start');

        async.elapse(const Duration(minutes: 4, seconds: 59));
        expect(sync.triggers, 1);

        async.elapse(const Duration(seconds: 1));
        expect(sync.triggers, 2);

        async.elapse(const Duration(minutes: 10));
        expect(sync.triggers, 4, reason: 'ticks at 10 and 15 minutes');
      });
    });

    test('post-write nudges collapse into a single sweep', () {
      fakeAsync((async) {
        build();
        scheduler.start();
        async.flushMicrotasks();
        expect(sync.triggers, 1);

        scheduler.notifyLocalWrite();
        async.elapse(const Duration(milliseconds: 500));
        scheduler.notifyLocalWrite();
        scheduler.notifyLocalWrite();
        async.elapse(const Duration(milliseconds: 999));
        expect(sync.triggers, 1, reason: 'debounce window still open');

        async.elapse(const Duration(milliseconds: 1));
        expect(sync.triggers, 2, reason: 'one nudge sweep fired');
      });
    });

    test('triggers arriving during a sweep share one execution', () {
      fakeAsync((async) {
        build(nudge: const Duration(milliseconds: 10));
        sync.gate = Completer<void>();

        scheduler.start();
        async.flushMicrotasks();
        expect(sync.executions, 1);

        connectivity.emit(true);
        scheduler.notifyLocalWrite();
        async.elapse(const Duration(milliseconds: 10));
        async.flushMicrotasks();

        expect(sync.triggers, 3, reason: 'app start + edge + nudge');
        expect(sync.executions, 1, reason: 'all joined the in-flight sweep');

        sync.gate!.complete();
        async.flushMicrotasks();
        expect(sync.executions, 1);
      });
    });

    test('dispose stops every trigger', () {
      fakeAsync((async) {
        build(nudge: const Duration(milliseconds: 10));
        scheduler.start();
        async.flushMicrotasks();
        expect(sync.triggers, 1);

        scheduler.dispose();
        async.flushMicrotasks();

        connectivity.emit(true);
        scheduler.notifyLocalWrite();
        async.elapse(const Duration(minutes: 10));

        expect(sync.triggers, 1);
      });
    });
  });
}
