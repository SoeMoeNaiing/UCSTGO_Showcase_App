import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Persists a stable kiosk/device identifier across restarts.
class DeviceIdService {
  DeviceIdService(this._prefs, {Uuid uuid = const Uuid()}) : _uuid = uuid;

  static const String _storageKey = 'ucstgo_showcase_device_id';

  final SharedPreferences _prefs;
  final Uuid _uuid;

  Future<String> getOrCreateDeviceId() async {
    final existing = _prefs.getString(_storageKey);
    if (existing != null && existing.trim().isNotEmpty) {
      return existing;
    }
    final generated = 'device-${_uuid.v4()}';
    await _prefs.setString(_storageKey, generated);
    return generated;
  }
}
