import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/controllers/feedback_controller.dart';

class _FakeSubmitter implements FeedbackSubmitter {
  SubmissionResult result = const SubmissionAccepted(SyncStatus.pending);
  Object? error;
  Completer<SubmissionResult>? gate;
  final calls = <EmojiChoice>[];

  @override
  Future<SubmissionResult> submit(EmojiChoice choice) async {
    calls.add(choice);
    final gate = this.gate;
    if (gate != null) {
      return gate.future;
    }
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return result;
  }
}

/// Iteration 20 — FeedbackController gate (§10.6, §2.1.7).
///
/// Every transition is driven through a `ProviderContainer` with a fake
/// submitter: no widget tree, no `BuildContext`, no repository, no clock.
void main() {
  late _FakeSubmitter submitter;
  late ProviderContainer container;
  late FeedbackController controller;
  late List<FeedbackState> states;

  void build() {
    submitter = _FakeSubmitter();
    container = ProviderContainer(
      overrides: [
        feedbackSubmitterProvider.overrideWith((ref) => submitter),
      ],
    );
    addTearDown(container.dispose);
    controller = container.read(feedbackControllerProvider.notifier);
    states = <FeedbackState>[];
    container.listen(
      feedbackControllerProvider,
      (previous, next) => states.add(next),
      fireImmediately: true,
    );
  }

  group('FeedbackController (§10.6)', () {
    test('starts idle', () {
      build();

      expect(container.read(feedbackControllerProvider), const FeedbackIdle());
      expect(states, [const FeedbackIdle()]);
    });

    test('select walks selecting → submitting → success', () async {
      build();
      submitter.gate = Completer<SubmissionResult>();

      final pending = controller.select(EmojiChoice.satisfied);

      expect(states, [
        const FeedbackIdle(),
        FeedbackSelecting(EmojiChoice.satisfied),
        FeedbackSubmitting(EmojiChoice.satisfied),
      ]);

      submitter.gate!.complete(const SubmissionAccepted(SyncStatus.synced));
      await pending;

      expect(
        container.read(feedbackControllerProvider),
        FeedbackSuccess(EmojiChoice.satisfied),
      );
      expect(states.last, FeedbackSuccess(EmojiChoice.satisfied));
      expect(submitter.calls, [EmojiChoice.satisfied]);
    });

    test('offline acceptance (pending) still shows success', () async {
      build();
      submitter.result = const SubmissionAccepted(SyncStatus.pending);

      await controller.select(EmojiChoice.neutral);

      expect(
        container.read(feedbackControllerProvider),
        FeedbackSuccess(EmojiChoice.neutral),
      );
    });

    test('a second select while submitting is ignored', () async {
      build();
      submitter.gate = Completer<SubmissionResult>();

      final first = controller.select(EmojiChoice.satisfied);
      await controller.select(EmojiChoice.dissatisfied);

      expect(submitter.calls, [EmojiChoice.satisfied]);
      expect(states.last, FeedbackSubmitting(EmojiChoice.satisfied));

      submitter.gate!.complete(const SubmissionAccepted(SyncStatus.pending));
      await first;

      expect(
        container.read(feedbackControllerProvider),
        FeedbackSuccess(EmojiChoice.satisfied),
      );
    });

    test('429 maps to a cooldown with user-facing copy', () async {
      build();
      submitter.result = const SubmissionRefused(
        SyncStatus.rejected,
        'rate_limited_for_device',
      );

      await controller.select(EmojiChoice.satisfied);

      final state = container.read(feedbackControllerProvider);
      expect(state, isA<FeedbackCooldown>());
      final message = (state as FeedbackCooldown).message;
      expect(message, contains('wait'));
      expect(message, isNot(contains('rate_limited')));
    });

    test('400 maps to an error with user-facing copy', () async {
      build();
      submitter.result = const SubmissionRefused(
        SyncStatus.failedPermanent,
        'bad_payload',
      );

      await controller.select(EmojiChoice.satisfied);

      final state = container.read(feedbackControllerProvider);
      expect(state, isA<FeedbackError>());
      final message = (state as FeedbackError).message;
      expect(message, contains('staff'));
      expect(message, isNot(contains('bad_payload')));
    });

    test('a throwing submitter becomes a friendly error', () async {
      build();
      submitter.error = Exception('socket exploded');

      await controller.select(EmojiChoice.satisfied);

      final state = container.read(feedbackControllerProvider);
      expect(state, isA<FeedbackError>());
      final message = (state as FeedbackError).message;
      expect(message, isNot(contains('socket exploded')));
      expect(message, contains('try again'));
    });

    test('success and cooldown reject selection until reset()', () async {
      build();
      await controller.select(EmojiChoice.satisfied);
      await controller.select(EmojiChoice.neutral);
      expect(submitter.calls, [EmojiChoice.satisfied]);

      controller.reset();
      expect(container.read(feedbackControllerProvider), const FeedbackIdle());

      await controller.select(EmojiChoice.neutral);
      expect(submitter.calls, [EmojiChoice.satisfied, EmojiChoice.neutral]);
    });

    test('cooldown does not start another submission', () async {
      build();
      submitter.result = const SubmissionRefused(
        SyncStatus.rejected,
        'rate_limited',
      );

      await controller.select(EmojiChoice.satisfied);
      await controller.select(EmojiChoice.neutral);

      expect(submitter.calls, [EmojiChoice.satisfied]);
    });

    test('error state accepts a retry', () async {
      build();
      submitter.error = Exception('boom');
      await controller.select(EmojiChoice.satisfied);
      expect(container.read(feedbackControllerProvider), isA<FeedbackError>());

      submitter.error = null;
      await controller.select(EmojiChoice.neutral);

      expect(submitter.calls, [EmojiChoice.satisfied, EmojiChoice.neutral]);
      expect(
        container.read(feedbackControllerProvider),
        FeedbackSuccess(EmojiChoice.neutral),
      );
    });

    test('controller has no BuildContext or widget import (§2.1.7)', () {
      final source = File(
        'lib/features/feedback/presentation/controllers/'
        'feedback_controller.dart',
      ).readAsStringSync();
      // Comments may *discuss* BuildContext; only code may not mention it.
      final code = source
          .replaceAll(RegExp(r'//.*'), '')
          .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');

      expect(code, isNot(contains('BuildContext')));
      expect(source, isNot(contains('flutter/material.dart')));
      expect(source, contains('package:flutter_riverpod/flutter_riverpod.dart'));
    });
  });
}
