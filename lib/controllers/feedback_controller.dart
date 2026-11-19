import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/submission_result.dart';
import '../models/sync_status.dart';
import '../providers.dart';
import '../models/emoji_choice.dart';
import './submit_feedback.dart';

/// Wired to `SubmitFeedback` at I21; I20 tests override the seam with fakes.
final feedbackSubmitterProvider = Provider<FeedbackSubmitter>((ref) {
  return ref.watch(submitFeedbackProvider);
});

/// Every state of the feedback flow — sealed so the I24 screen can `switch`
/// exhaustively and value-comparable so transitions are assertable (§10.6).
sealed class FeedbackState {
  const FeedbackState();
}

final class FeedbackIdle extends FeedbackState {
  const FeedbackIdle();

  @override
  bool operator ==(Object other) => other is FeedbackIdle;

  @override
  int get hashCode => 1;
}

final class FeedbackSelecting extends FeedbackState {
  const FeedbackSelecting(this.choice);

  final EmojiChoice choice;

  @override
  bool operator ==(Object other) =>
      other is FeedbackSelecting && other.choice == choice;

  @override
  int get hashCode => Object.hash(FeedbackSelecting, choice);
}

final class FeedbackSubmitting extends FeedbackState {
  const FeedbackSubmitting(this.choice);

  final EmojiChoice choice;

  @override
  bool operator ==(Object other) =>
      other is FeedbackSubmitting && other.choice == choice;

  @override
  int get hashCode => Object.hash(FeedbackSubmitting, choice);
}

final class FeedbackSuccess extends FeedbackState {
  const FeedbackSuccess(this.choice);

  final EmojiChoice choice;

  @override
  bool operator ==(Object other) =>
      other is FeedbackSuccess && other.choice == choice;

  @override
  int get hashCode => Object.hash(FeedbackSuccess, choice);
}

final class FeedbackCooldown extends FeedbackState {
  const FeedbackCooldown(this.message);

  /// User-facing explanation of the wait. Never a log-safe internal reason.
  final String message;

  @override
  bool operator ==(Object other) =>
      other is FeedbackCooldown && other.message == message;

  @override
  int get hashCode => Object.hash(FeedbackCooldown, message);
}

final class FeedbackError extends FeedbackState {
  const FeedbackError(this.message);

  /// User-facing recovery instruction. Never a log-safe internal reason.
  final String message;

  @override
  bool operator ==(Object other) =>
      other is FeedbackError && other.message == message;

  @override
  int get hashCode => Object.hash(FeedbackError, message);
}

final feedbackControllerProvider =
    NotifierProvider<FeedbackController, FeedbackState>(FeedbackController.new);

/// Pure state machine for one visitor's feedback action (§2.1.7).
///
/// No `BuildContext`, no widgets, no repository: just a submitter seam and
/// the §6.6 result vocabulary. All UI copy lives here as state messages so
/// the I24 screen never has to interpret a status code.
class FeedbackController extends Notifier<FeedbackState> {
  @override
  FeedbackState build() => const FeedbackIdle();

  /// Only idle (first choice) and error (retry) accept a selection.
  /// Success, cooldown, selecting and submitting are terminal until
  /// [reset] is called by the I24 prompt flow.
  bool get _canSelect => state is FeedbackIdle || state is FeedbackError;

  /// Walks `idle → selecting → submitting → success | cooldown | error`.
  ///
  /// The two first states are emitted synchronously before the first
  /// `await`, so the screen can show a pressed face while the durable write
  /// runs. Re-entrant calls are dropped before touching the submitter.
  Future<void> select(EmojiChoice choice) async {
    if (!_canSelect) {
      return;
    }

    state = FeedbackSelecting(choice);
    state = FeedbackSubmitting(choice);

    final SubmissionResult result;
    try {
      result = await ref.read(feedbackSubmitterProvider).submit(choice);
    } on FeedbackValidationException catch (error) {
      state = FeedbackError(error.message);
      return;
    } catch (_) {
      state = const FeedbackError('Something went wrong. Please try again.');
      return;
    }

    state = switch (result) {
      SubmissionAccepted() => FeedbackSuccess(choice),
      SubmissionRefused(status: SyncStatus.rejected) => const FeedbackCooldown(
          'Thanks for your feedback! Please wait a moment before trying again.',
        ),
      SubmissionRefused() => const FeedbackError(
          "We couldn't save your feedback. Please tell a staff member.",
        ),
    };
  }

  /// Returns the machine to `idle` for the next visitor / next question.
  void reset() => state = const FeedbackIdle();
}
