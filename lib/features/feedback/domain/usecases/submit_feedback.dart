import 'package:ucstgo_showcase_flutter_app/core/domain/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';

import '../entities/emoji_choice.dart';
import '../entities/feedback.dart';
import '../repositories/feedback_repository.dart';

/// Anonymous device identity needed by the submit path (§6.3).
///
/// Implemented by an adapter over `DeviceIdService` in the wiring layer;
/// the domain never imports `shared_preferences` (§4.2).
abstract interface class DeviceIdReader {
  Future<String> read();
}

/// Starts the post-submit cooldown (§7 layer 1).
///
/// Implemented by an adapter over `CooldownService` in the wiring layer.
abstract interface class FeedbackCooldownStarter {
  Future<void> start();
}

/// Idempotency-key factory — `Uuid().v4` in production, a counter in tests.
typedef ClientIdGenerator = String Function();

/// Invalid generated data (not a network problem): surfaced as user-facing
/// copy by the controller, distinct from the generic caught-exception error.
final class FeedbackValidationException implements Exception {
  const FeedbackValidationException(this.message);

  /// Safe to show to a visitor.
  final String message;

  @override
  String toString() => 'FeedbackValidationException($message)';
}

/// The controller's only view of submission — declared here in `domain/` so
/// the wiring layer can implement it without importing `presentation/`.
abstract interface class FeedbackSubmitter {
  Future<SubmissionResult> submit(EmojiChoice choice);
}

/// One visitor action: identity → entity → local-first submit → cooldown.
///
/// Pure Dart (§4.2): every side effect is an injected port. The repository
/// keeps the local-first promise — this use case never touches the network
/// directly and never blocks the visitor's thank-you on an upload.
class SubmitFeedback implements FeedbackSubmitter {
  SubmitFeedback({
    required this.repository,
    required this.deviceIds,
    required this.cooldown,
    required this.newClientId,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final FeedbackRepository repository;
  final DeviceIdReader deviceIds;
  final FeedbackCooldownStarter cooldown;
  final ClientIdGenerator newClientId;

  /// Injectable clock; the entity requires UTC.
  final DateTime Function() now;

  @override
  Future<SubmissionResult> submit(EmojiChoice choice) async {
    final clientId = newClientId().trim();
    final deviceId = (await deviceIds.read()).trim();
    if (clientId.isEmpty || deviceId.isEmpty) {
      throw const FeedbackValidationException(
        "We couldn't prepare your feedback. Please try again.",
      );
    }

    final feedback = Feedback(
      clientId: clientId,
      deviceId: deviceId,
      emojiChoice: choice,
      createdAt: now().toUtc(),
    );

    final result = await repository.submit(feedback);

    // §7: lock the action after an accepted submission, and after a 429 so
    // a rejected visitor cannot hammer the server again. A 400 is a bug,
    // not a rate limit — leave the cooldown alone.
    if (result is SubmissionAccepted ||
        (result is SubmissionRefused &&
            result.status == SyncStatus.rejected)) {
      await cooldown.start();
    }

    return result;
  }
}
