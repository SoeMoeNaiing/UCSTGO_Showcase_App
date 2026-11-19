import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Persistence seam for the anonymous device id — injectable for tests.
abstract interface class DeviceIdStorage {
  Future<String?> read();

  Future<void> write(String value);
}

/// Production storage: `shared_preferences` (§6.3).
class SharedPreferencesDeviceIdStorage implements DeviceIdStorage {
  const SharedPreferencesDeviceIdStorage();

  /// Stable key; changing it would orphan every existing device identity.
  static const storageKey = 'device_id';

  @override
  Future<String?> read() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(storageKey);
  }

  @override
  Future<void> write(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(storageKey, value);
  }
}

/// Anonymous, stable device identity — PROJECT_PROCESS.md §6.3, §2.4.
///
/// Generated **once** on first launch as a UUID v4 and reused for the
/// device's lifetime. There is no account, no name, no PII — just an
/// opaque id that lets the server apply per-device rate limits (§6.8).
///
/// The id is cached in memory after the first read, and concurrent first
/// calls coalesce into a single generation + write (two widgets requesting
/// identity at startup must not create two ids).
class DeviceIdService {
  DeviceIdService({required this.storage, Uuid? uuid})
    : uuid = uuid ?? const Uuid();

  final DeviceIdStorage storage;
  final Uuid uuid;

  String? _cached;
  Future<String>? _inFlight;

  /// Returns the persisted device id, creating it on first use.
  Future<String> getOrCreate() {
    final cached = _cached;
    if (cached != null) {
      return Future.value(cached);
    }
    return _inFlight ??= _loadOrCreate().whenComplete(() => _inFlight = null);
  }

  Future<String> _loadOrCreate() async {
    final stored = await storage.read();
    if (stored != null && stored.trim().isNotEmpty) {
      _cached = stored;
      return stored;
    }

    final created = uuid.v4();
    await storage.write(created);
    _cached = created;
    return created;
  }
}
