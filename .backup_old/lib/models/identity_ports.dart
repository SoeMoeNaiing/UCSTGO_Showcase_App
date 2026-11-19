// Ports shared by the feedback and rating submit paths (§6.3, §6.5).
//
// Pure Dart: plugin-backed implementations live in the provider graph,
// never in `domain/` (§4.2).

/// Anonymous device identity needed by a submit path (§6.3).
abstract interface class DeviceIdReader {
  Future<String> read();
}

/// Idempotency-key factory — `Uuid().v4` in production, a counter in tests.
typedef ClientIdGenerator = String Function();
