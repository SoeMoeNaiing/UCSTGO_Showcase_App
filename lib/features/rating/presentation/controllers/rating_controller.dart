import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/submission_result.dart';
import '../../../../core/domain/sync_status.dart';
import '../../../../core/providers.dart';
import '../../domain/usecases/submit_rating.dart';

/// Wired to `SubmitRating` in the provider graph; tests override the seam.
final ratingSubmitterProvider = Provider<RatingSubmitter>((ref) {
  return ref.watch(submitRatingProvider);
});

/// Every state of one rating action (§10.7).
sealed class RatingState {
  const RatingState();
}

final class RatingIdle extends RatingState {
  const RatingIdle();

  @override
  bool operator ==(Object other) => other is RatingIdle;

  @override
  int get hashCode => 1;
}

final class RatingSubmitting extends RatingState {
  const RatingSubmitting({required this.projectId, required this.score});

  final String projectId;
  final int score;

  @override
  bool operator ==(Object other) =>
      other is RatingSubmitting &&
      other.projectId == projectId &&
      other.score == score;

  @override
  int get hashCode => Object.hash(RatingSubmitting, projectId, score);
}

final class RatingSuccess extends RatingState {
  const RatingSuccess({required this.projectId, required this.score});

  final String projectId;
  final int score;

  @override
  bool operator ==(Object other) =>
      other is RatingSuccess &&
      other.projectId == projectId &&
      other.score == score;

  @override
  int get hashCode => Object.hash(RatingSuccess, projectId, score);
}

final class RatingCooldown extends RatingState {
  const RatingCooldown(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      other is RatingCooldown && other.message == message;

  @override
  int get hashCode => Object.hash(RatingCooldown, message);
}

final class RatingError extends RatingState {
  const RatingError(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      other is RatingError && other.message == message;

  @override
  int get hashCode => Object.hash(RatingError, message);
}

final ratingControllerProvider =
    NotifierProvider<RatingController, RatingState>(RatingController.new);

/// Pure state machine for rating one showcase project (§2.1.7).
class RatingController extends Notifier<RatingState> {
  @override
  RatingState build() => const RatingIdle();

  Future<void> submit({
    required String projectId,
    required int score,
  }) async {
    if (state is! RatingIdle && state is! RatingError) {
      return;
    }

    state = RatingSubmitting(projectId: projectId, score: score);

    final SubmissionResult result;
    try {
      result = await ref.read(ratingSubmitterProvider).submit(
            projectId: projectId,
            score: score,
          );
    } on RatingValidationException catch (error) {
      state = RatingError(error.message);
      return;
    } catch (_) {
      state = const RatingError('Something went wrong. Please try again.');
      return;
    }

    state = switch (result) {
      SubmissionAccepted() => RatingSuccess(projectId: projectId, score: score),
      SubmissionRefused(status: SyncStatus.rejected) => const RatingCooldown(
          'Thanks for rating! Please wait a moment before rating again.',
        ),
      SubmissionRefused() => const RatingError(
          "We couldn't save your rating. Please tell a staff member.",
        ),
    };
  }

  void reset() => state = const RatingIdle();
}
