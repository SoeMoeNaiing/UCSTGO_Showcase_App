import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../features/feedback/data/datasources/feedback_local_datasource.dart';
import '../features/feedback/data/datasources/feedback_remote_datasource.dart';
import '../features/feedback/data/local/app_database.dart';
import '../features/feedback/data/repositories/feedback_repository_impl.dart';
import '../features/feedback/domain/repositories/feedback_repository.dart';
import '../features/feedback/domain/usecases/submit_feedback.dart';
import '../services/cooldown_service.dart';
import '../services/device_id_service.dart';

/// Minimal production graph for the submit path (I21).
///
/// Deliberately small: the sync engine/scheduler and router arrive at I24.
/// Providers are lazy, so opening the database or touching platform storage
/// happens only when something actually reads them.
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final deviceIdServiceProvider = Provider<DeviceIdService>(
  (ref) => DeviceIdService(storage: const SharedPreferencesDeviceIdStorage()),
);

final cooldownServiceProvider = Provider<CooldownService>(
  (ref) => CooldownService(storage: const SharedPreferencesCooldownStorage()),
);

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return FeedbackRepositoryImpl(
    local: FeedbackLocalDataSource(database),
    remote: const UnavailableFeedbackRemoteDataSource(),
    // Phases 1–5 have no backend: never attempt an upload. Phase 6 replaces
    // both this seam and the connectivity check with the real services.
    isOnline: () async => false,
  );
});

final submitFeedbackProvider = Provider<SubmitFeedback>((ref) {
  return SubmitFeedback(
    repository: ref.watch(feedbackRepositoryProvider),
    deviceIds: _DeviceIdReaderAdapter(ref.watch(deviceIdServiceProvider)),
    cooldown: _CooldownAdapter(ref.watch(cooldownServiceProvider)),
    newClientId: const Uuid().v4,
  );
});

/// Adapters keep plugin-backed services out of `domain/` (§4.2).
class _DeviceIdReaderAdapter implements DeviceIdReader {
  const _DeviceIdReaderAdapter(this._service);

  final DeviceIdService _service;

  @override
  Future<String> read() => _service.getOrCreate();
}

class _CooldownAdapter implements FeedbackCooldownStarter {
  const _CooldownAdapter(this._service);

  final CooldownService _service;

  @override
  Future<void> start() => _service.start(CooldownAction.feedback);
}
