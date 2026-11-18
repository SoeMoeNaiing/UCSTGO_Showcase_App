import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/services/device_id_service.dart';

/// Fake storage standing in for `shared_preferences`.
class _FakeStorage implements DeviceIdStorage {
  _FakeStorage([this.value]);

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

/// Iteration 12 — DeviceIdService invariants (PROJECT_PROCESS.md §6.3).
void main() {
  final uuidV4 = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  );

  group('DeviceIdService (§6.3)', () {
    test('first call creates and persists a UUID v4', () async {
      final storage = _FakeStorage();
      final service = DeviceIdService(storage: storage);

      final id = await service.getOrCreate();

      expect(uuidV4.hasMatch(id), isTrue, reason: 'got "$id"');
      expect(storage.value, id);
      expect(storage.writes, 1);
    });

    test('repeated calls reuse the cached id without extra writes', () async {
      final storage = _FakeStorage();
      final service = DeviceIdService(storage: storage);

      final first = await service.getOrCreate();
      final second = await service.getOrCreate();
      final third = await service.getOrCreate();

      expect(second, first);
      expect(third, first);
      expect(storage.writes, 1);
    });

    test('a new service instance returns the stored id after restart', () async {
      final storage = _FakeStorage();

      final beforeRestart = await DeviceIdService(storage: storage).getOrCreate();
      final afterRestart = await DeviceIdService(storage: storage).getOrCreate();

      expect(afterRestart, beforeRestart);
      expect(storage.writes, 1, reason: 'restart must not regenerate');
    });

    test('an empty stored value is treated as missing and regenerated', () async {
      final storage = _FakeStorage('   ');
      final service = DeviceIdService(storage: storage);

      final id = await service.getOrCreate();

      expect(uuidV4.hasMatch(id), isTrue);
      expect(storage.value, id);
      expect(storage.writes, 1);
    });

    test('concurrent first calls coalesce into one id and one write', () async {
      final storage = _FakeStorage();
      final service = DeviceIdService(storage: storage);

      final ids = await Future.wait([
        service.getOrCreate(),
        service.getOrCreate(),
        service.getOrCreate(),
      ]);

      expect(ids.toSet(), hasLength(1));
      expect(storage.writes, 1);
    });
  });
}
