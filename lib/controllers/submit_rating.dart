import 'package:ucstgo_showcase_flutter_app/models/identity_ports.dart';
import 'package:ucstgo_showcase_flutter_app/models/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/models/sync_status.dart';

import '../models/rating.dart';
import '../repositories/rating_repository.dart';

/// Starts the rating cooldown (§7 layer 1), implemented in the wiring layer
/// by an adapter over `CooldownService` with `CooldownAction.rating`.
abstract interface class RatingCooldownStarter {
  Future<void> start();
}

/// Invalid visitor input (not a network problem).
final class RatingValidationException implements Exception {
  const RatingValidationException(this.message);

  /// Safe to show to a visitor.
  final String message;

  @override
  String toString() => 'RatingValidationException($message)';
}

/// The rating controller's only view of submission (declared in `domain/`
/// so the wiring layer never imports `presentation/`).
abstract interface class RatingSubmitter {
  Future<SubmissionResult> submit({
    required String projectId,
    required int score,
  });
}

/// One rating action: validate → identity → durable submit → cooldown.
///
/// Pure Dart; side effects are injected ports. The repository keeps the
/// local-first promise, so an offline rating is still a success.
class SubmitRating implements RatingSubmitter {
  SubmitRating({
    required this.repository,
    required this.deviceIds,
    required this.cooldown,
    required this.newClientId,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final RatingRepository repository;
  final DeviceIdReader deviceIds;
  final RatingCooldownStarter cooldown;
  final ClientIdGenerator newClientId;
  final DateTime Function() now;

  @override
  Future<SubmissionResult> submit({
    required String projectId,
    required int score,
  }) async {
    if (projectId.trim().isEmpty || score < 1 || score > 5) {
      throw const RatingValidationException(
        "We couldn't save your rating. Please try again.",
      );
    }

    final clientId = newClientId().trim();
    final deviceId = (await deviceIds.read()).trim();
    if (clientId.isEmpty || deviceId.isEmpty) {
      throw const RatingValidationException(
        "We couldn't save your rating. Please try again.",
      );
    }

    final rating = Rating(
      clientId: clientId,
      deviceId: deviceId,
      projectId: projectId,
      score: score,
      createdAt: now().toUtc(),
    );

    final result = await repository.submit(rating);

    // Same cooldown policy as feedback (§7): accepted and 429, not 400.
    if (result is SubmissionAccepted ||
        (result is SubmissionRefused &&
            result.status == SyncStatus.rejected)) {
      await cooldown.start();
    }

    return result;
  }
}
