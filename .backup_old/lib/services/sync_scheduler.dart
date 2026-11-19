import 'dart:async';

import './connectivity_service.dart';
import './sync_service.dart';

/// Wires the four §6.4 sync triggers into one coalesced background sweep.
///
/// Triggers:
/// 1. [start] — app launch, after connectivity's first probe.
/// 2. [ConnectivityStatus.online] rising edge — the network came back.
/// 3. A periodic timer (5 minutes by default).
/// 4. [notifyLocalWrite] — a debounced nudge after each durable save.
///
/// Coalescing has two layers: repeated nudges share one timer here, and
/// overlapping sweeps collapse inside [SyncRunner.syncAll]. No trigger
/// starts a sweep while connectivity reports offline; the rising edge is
/// the recovery path.
class SyncScheduler {
  SyncScheduler({
    required this.sync,
    required this.connectivity,
    this.interval = const Duration(minutes: 5),
    this.nudgeDelay = const Duration(seconds: 1),
  }) : assert(interval > Duration.zero, 'interval must be positive'),
       assert(nudgeDelay >= Duration.zero, 'nudgeDelay must not be negative');

  final SyncRunner sync;
  final ConnectivityStatus connectivity;

  /// Periodic sweep cadence (§13: 5 minutes).
  final Duration interval;

  /// Post-write debounce window (§6.4: ~1 second).
  final Duration nudgeDelay;

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _periodicTimer;
  Timer? _nudgeTimer;
  bool _started = false;
  bool _disposed = false;

  /// Starts observing triggers and performs the app-start sweep.
  ///
  /// Bootstrap may call this unawaited: the returned future completes after
  /// the initial sweep, never at the end of the scheduler's life.
  Future<void> start() async {
    if (_started || _disposed) {
      return;
    }
    _started = true;

    _connectivitySubscription = connectivity.online.listen(
      _onConnectivityChange,
    );
    _periodicTimer = Timer.periodic(interval, (_) => unawaited(_trigger()));

    final online = await connectivity.start();
    if (online && !_disposed) {
      await sync.syncAll();
    }
  }

  /// Requests a sweep shortly after a durable local write.
  ///
  /// Repeated calls inside [nudgeDelay] collapse into one timer. Other
  /// triggers do **not** cancel a pending nudge: a sweep that started
  /// before the write may already have queried the queue, so the nudge
  /// remains the safety net that picks the new row up.
  void notifyLocalWrite() {
    if (_disposed) {
      return;
    }
    _nudgeTimer?.cancel();
    _nudgeTimer = Timer(nudgeDelay, () => unawaited(_trigger()));
  }

  void _onConnectivityChange(bool online) {
    if (online) {
      unawaited(_trigger());
    }
  }

  Future<void> _trigger() async {
    if (_disposed) {
      return;
    }
    if (!connectivity.isOnline) {
      return;
    }
    await sync.syncAll();
  }

  void _cancelNudge() {
    _nudgeTimer?.cancel();
    _nudgeTimer = null;
  }

  /// Stops all timers and the link subscription. Idempotent.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _cancelNudge();
    _periodicTimer?.cancel();
    _periodicTimer = null;

    final subscription = _connectivitySubscription;
    _connectivitySubscription = null;
    await subscription?.cancel();
  }
}
