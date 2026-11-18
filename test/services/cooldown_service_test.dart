import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ucstgo_showcase_flutter_app/services/cooldown_service.dart';

/// Fake persisted deadlines; the clock stays in the test.
class _FakeCooldownStorage implements CooldownStorage {
  final deadlines = <CooldownAction, DateTime>{};
  int writes = 0;

  @override
  Future<DateTime?> readDeadline(CooldownAction action) async =>
      deadlines[action];

  @override
  Future<void> writeDeadline(
    CooldownAction action,
    DateTime deadline,
  ) async {
    deadlines[action] = deadline;
    writes++;
  }

  @override
  Future<void> clearDeadline(CooldownAction action) async {
    deadlines.remove(action);
  }
}

/// Iteration 13 — CooldownService invariants (PROJECT_PROCESS.md §7).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeCooldownStorage storage;
  late DateTime now;
  late CooldownService service;

  setUp(() {
    storage = _FakeCooldownStorage();
    now = DateTime.utc(2026, 11, 18, 12);
    service = CooldownService(storage: storage, now: () => now);
  });

  group('CooldownService (§7 client cooldown)', () {
    test('starts allowed', () async {
      expect(await service.canSubmit(CooldownAction.feedback), isTrue);
      expect(await service.timeRemaining(CooldownAction.feedback),
          Duration.zero);
    });

    test('start blocks and persists the 30s deadline', () async {
      await service.start(CooldownAction.feedback);

      expect(await service.canSubmit(CooldownAction.feedback), isFalse);
      expect(
        await service.timeRemaining(CooldownAction.feedback),
        const Duration(seconds: 30),
      );
      expect(
        storage.deadlines[CooldownAction.feedback],
        now.add(const Duration(seconds: 30)),
      );
      expect(storage.writes, 1);
    });

    test('exactly 30s later the action is allowed again', () async {
      await service.start(CooldownAction.feedback);

      now = now.add(const Duration(seconds: 29));
      expect(await service.canSubmit(CooldownAction.feedback), isFalse);

      now = now.add(const Duration(seconds: 1));
      expect(await service.canSubmit(CooldownAction.feedback), isTrue);
    });

    test('a new service instance still sees the persisted deadline', () async {
      await service.start(CooldownAction.feedback);
      final restarted = CooldownService(storage: storage, now: () => now);

      expect(await restarted.canSubmit(CooldownAction.feedback), isFalse);

      now = now.add(const Duration(seconds: 30));
      expect(await restarted.canSubmit(CooldownAction.feedback), isTrue);
    });

    test('feedback and rating cooldowns do not cross-block', () async {
      await service.start(CooldownAction.feedback);

      expect(await service.canSubmit(CooldownAction.feedback), isFalse);
      expect(await service.canSubmit(CooldownAction.rating), isTrue);

      now = now.add(const Duration(seconds: 15));
      await service.start(CooldownAction.rating);

      now = now.add(const Duration(seconds: 15));
      expect(await service.canSubmit(CooldownAction.feedback), isTrue);
      expect(await service.canSubmit(CooldownAction.rating), isFalse);
    });

    test('clear ends the cooldown immediately', () async {
      await service.start(CooldownAction.rating);

      await service.clear(CooldownAction.rating);

      expect(await service.canSubmit(CooldownAction.rating), isTrue);
      expect(storage.deadlines, isEmpty);
    });

    test('a backwards clock is capped at one cooldown window', () async {
      storage.deadlines[CooldownAction.feedback] =
          now.add(const Duration(hours: 3));

      expect(
        await service.timeRemaining(CooldownAction.feedback),
        const Duration(seconds: 30),
      );
    });

    test('remaining emits the countdown and completes at zero', () async {
      await service.start(CooldownAction.feedback);
      final values = <Duration>[];

      await for (final value in service.remaining(
        CooldownAction.feedback,
        tick: const Duration(milliseconds: 1),
      )) {
        values.add(value);
        if (values.length == 1) {
          now = now.add(const Duration(seconds: 30));
        }
      }

      expect(values, [
        const Duration(seconds: 30),
        Duration.zero,
      ]);
    });
  });

  group('SharedPreferencesCooldownStorage', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('round-trips UTC deadlines and isolates actions', () async {
      const adapter = SharedPreferencesCooldownStorage();
      final deadline = DateTime.utc(2026, 11, 18, 12, 0, 30);

      await adapter.writeDeadline(CooldownAction.feedback, deadline);

      expect(await adapter.readDeadline(CooldownAction.feedback), deadline);
      expect(await adapter.readDeadline(CooldownAction.rating), isNull);

      await adapter.clearDeadline(CooldownAction.feedback);
      expect(await adapter.readDeadline(CooldownAction.feedback), isNull);
    });

    test('a corrupt stored deadline reads as no cooldown', () async {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        SharedPreferencesCooldownStorage.keyFor(CooldownAction.feedback),
        'not-a-date',
      );

      expect(
        await const SharedPreferencesCooldownStorage()
            .readDeadline(CooldownAction.feedback),
        isNull,
      );
    });
  });
}
