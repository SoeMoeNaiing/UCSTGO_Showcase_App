import 'package:shared_preferences/shared_preferences.dart';

/// The two independently rate-limited visitor actions (§7).
enum CooldownAction {
  feedback('feedback'),
  rating('rating');

  const CooldownAction(this.storageKey);

  /// Suffix used in the persisted key; never rename (would orphan deadlines).
  final String storageKey;
}

/// Persistence seam for cooldown deadlines — injectable for tests.
abstract interface class CooldownStorage {
  Future<DateTime?> readDeadline(CooldownAction action);

  Future<void> writeDeadline(CooldownAction action, DateTime deadline);

  Future<void> clearDeadline(CooldownAction action);
}

/// Production storage: one ISO-8601 UTC deadline per action (§7).
class SharedPreferencesCooldownStorage implements CooldownStorage {
  const SharedPreferencesCooldownStorage();

  static String keyFor(CooldownAction action) =>
      'cooldown_deadline_${action.storageKey}';

  @override
  Future<DateTime?> readDeadline(CooldownAction action) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(keyFor(action));
    if (raw == null) {
      return null;
    }
    // Corrupt values are treated as "no cooldown" — never lock the kiosk.
    return DateTime.tryParse(raw)?.toUtc();
  }

  @override
  Future<void> writeDeadline(CooldownAction action, DateTime deadline) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      keyFor(action),
      deadline.toUtc().toIso8601String(),
    );
  }

  @override
  Future<void> clearDeadline(CooldownAction action) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(keyFor(action));
  }
}

/// Client-side UX cooldown, 30s per action by default — §7 layer 1.
///
/// This is **not** security: the server rate limit (§6.8) stays the law.
/// The cooldown only stops rapid repeat taps and survives restarts through
/// a persisted deadline, so killing the app does not reset it.
///
/// The clock and storage are injected so the 30s window is tested in
/// milliseconds instead of real time.
class CooldownService {
  CooldownService({
    required this.storage,
    this.duration = const Duration(seconds: 30),
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final CooldownStorage storage;

  /// Default 30s, tunable per §13.
  final Duration duration;

  final DateTime Function() now;

  /// True when the action has no active cooldown.
  Future<bool> canSubmit(CooldownAction action) async =>
      (await timeRemaining(action)) == Duration.zero;

  /// Time left before [action] becomes available again.
  ///
  /// Capped at [duration] so a backwards clock jump cannot lock the kiosk
  /// for longer than one cooldown window.
  Future<Duration> timeRemaining(CooldownAction action) async {
    final deadline = await storage.readDeadline(action);
    if (deadline == null) {
      return Duration.zero;
    }

    final remaining = deadline.toUtc().difference(now().toUtc());
    if (remaining.isNegative) {
      return Duration.zero;
    }
    return remaining > duration ? duration : remaining;
  }

  /// Starts the cooldown for [action] after a successful submission.
  Future<void> start(CooldownAction action) async {
    await storage.writeDeadline(
      action,
      now().toUtc().add(duration),
    );
  }

  /// Ends the cooldown immediately (operator/testing escape hatch).
  Future<void> clear(CooldownAction action) => storage.clearDeadline(action);

  /// Emits the countdown until [action] is available, then completes.
  ///
  /// The first value is emitted immediately so a `StreamBuilder` can show
  /// the current state without an empty frame.
  Stream<Duration> remaining(
    CooldownAction action, {
    Duration tick = const Duration(seconds: 1),
  }) async* {
    while (true) {
      final left = await timeRemaining(action);
      yield left;
      if (left == Duration.zero) {
        return;
      }
      await Future<void>.delayed(tick);
    }
  }
}
