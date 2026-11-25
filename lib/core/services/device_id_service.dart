import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdService {
  DeviceIdService(this._prefs, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  static const String _storageKey = 'showcase_device_id_v1';

  final SharedPreferences _prefs;
  final Uuid _uuid;

  Future<String> getOrCreateDeviceId() async {
    final existing = _prefs.getString(_storageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final created = 'dev-${_uuid.v4()}';
    await _prefs.setString(_storageKey, created);
    return created;
  }
}
