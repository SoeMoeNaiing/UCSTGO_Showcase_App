import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import './repositories/feedback_local_datasource.dart';
import './repositories/feedback_remote_datasource.dart';
import './database/app_database.dart';
import './repositories/feedback_repository_impl.dart';
import './repositories/feedback_repository.dart';
import './controllers/submit_feedback.dart';
import './repositories/rating_local_datasource.dart';
import './repositories/rating_remote_datasource.dart';
import './repositories/rating_repository_impl.dart';
import './repositories/rating_repository.dart';
import './controllers/submit_rating.dart';
import './repositories/project_fixtures.dart';
import './models/project.dart';
import './services/cooldown_service.dart';
import './services/device_id_service.dart';
import './services/sync_service.dart';

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

/// Live countdowns for the I32 cooldown screens; tests override the streams.
/// A plain Provider caches the single stream instance (remaining() is an
/// async generator, so creating one per rebuild would restart the countdown).
final feedbackCooldownRemainingProvider = Provider<Stream<Duration>>((ref) {
  return ref
      .watch(cooldownServiceProvider)
      .remaining(CooldownAction.feedback);
});

final ratingCooldownRemainingProvider = Provider<Stream<Duration>>((ref) {
  return ref.watch(cooldownServiceProvider).remaining(CooldownAction.rating);
});

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

final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return RatingRepositoryImpl(
    local: RatingLocalDataSource(database),
    remote: const UnavailableRatingRemoteDataSource(),
    isOnline: () async => false,
  );
});

final submitRatingProvider = Provider<SubmitRating>((ref) {
  return SubmitRating(
    repository: ref.watch(ratingRepositoryProvider),
    deviceIds: _DeviceIdReaderAdapter(ref.watch(deviceIdServiceProvider)),
    cooldown: _RatingCooldownAdapter(ref.watch(cooldownServiceProvider)),
    newClientId: const Uuid().v4,
  );
});

/// One sync engine drains both queues; the I17 scheduler triggers it without
/// knowing there are two tables (§6.4).
final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    queue: ref.watch(feedbackRepositoryProvider),
    remote: const UnavailableFeedbackRemoteDataSource(),
    ratingQueue: ref.watch(ratingRepositoryProvider),
    ratingRemote: const UnavailableRatingRemoteDataSource(),
  );
});

final projectFixturesProvider = Provider<List<Project>>((ref) => projectFixtures);

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

class _RatingCooldownAdapter implements RatingCooldownStarter {
  const _RatingCooldownAdapter(this._service);

  final CooldownService _service;

  @override
  Future<void> start() => _service.start(CooldownAction.rating);
}
