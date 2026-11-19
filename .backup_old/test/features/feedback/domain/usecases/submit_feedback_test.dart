import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/models/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/models/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/models/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/models/feedback.dart';
import 'package:ucstgo_showcase_flutter_app/models/queued_feedback.dart';
import 'package:ucstgo_showcase_flutter_app/repositories/feedback_repository.dart';
import 'package:ucstgo_showcase_flutter_app/controllers/submit_feedback.dart';

class _FakeDeviceIds implements DeviceIdReader {
  String value = 'device-42';
  int reads = 0;

  @override
  Future<String> read() async {
    reads++;
    return value;
  }
}

class _FakeCooldown implements FeedbackCooldownStarter {
  int starts = 0;

  @override
  Future<void> start() async {
    starts++;
  }
}

class _FakeRepository implements FeedbackRepository {
  SubmissionResult result = const SubmissionAccepted(SyncStatus.pending);
  final submissions = <Feedback>[];

  @override
  Future<SubmissionResult> submit(Feedback feedback) async {
    submissions.add(feedback);
    return result;
  }

  @override
  Future<List<QueuedFeedback>> pending({int limit = 50}) =>
      throw UnimplementedError();

  @override
  Stream<int> watchPendingCount() => throw UnimplementedError();

  @override
  Future<void> applySyncStatus(
    String clientId,
    SyncStatus status, {
    DateTime? nextRetryAt,
  }) => throw UnimplementedError();
}

/// Iteration 21 — SubmitFeedback gate (§10.6, §6.3, §6.5, §7).
///
/// Pure use case: identity ports, idempotency key, UTC entity, local-first
/// result and cooldown policy — all with fakes and an injected clock.
void main() {
  late _FakeRepository repository;
  late _FakeDeviceIds deviceIds;
  late _FakeCooldown cooldown;
  late DateTime now;
  late SubmitFeedback useCase;
  late int clientCounter;

  SubmitFeedback build({String Function()? clientId}) => SubmitFeedback(
        repository: repository,
        deviceIds: deviceIds,
        cooldown: cooldown,
        newClientId: clientId ?? () => 'client-${++clientCounter}',
        now: () => now,
      );

  setUp(() {
    repository = _FakeRepository();
    deviceIds = _FakeDeviceIds();
    cooldown = _FakeCooldown();
    now = DateTime(2026, 11, 19, 10); // deliberately local
    clientCounter = 0;
    useCase = build();
  });

  group('SubmitFeedback (§10.6)', () {
    test('happy path builds the entity from the injected ports', () async {
      final result = await useCase.submit(EmojiChoice.satisfied);

      expect(result, isA<SubmissionAccepted>());
      expect(repository.submissions, hasLength(1));
      final feedback = repository.submissions.single;
      expect(feedback.clientId, 'client-1');
      expect(feedback.deviceId, 'device-42');
      expect(feedback.emojiChoice, EmojiChoice.satisfied);
      expect(feedback.createdAt, now.toUtc());
      expect(feedback.createdAt.isUtc, isTrue);
      expect(deviceIds.reads, 1);
      expect(cooldown.starts, 1, reason: '§7 layer 1 starts after success');
    });

    test('an offline (pending) submit is still a success', () async {
      repository.result = const SubmissionAccepted(SyncStatus.pending);

      final result = await useCase.submit(EmojiChoice.neutral);

      expect(result, const SubmissionAccepted(SyncStatus.pending));
      expect(repository.submissions, hasLength(1));
      expect(cooldown.starts, 1);
    });

    test('a 429 rejection starts the cooldown too', () async {
      repository.result = const SubmissionRefused(
        SyncStatus.rejected,
        'rate limited',
      );

      final result = await useCase.submit(EmojiChoice.satisfied);

      expect(result, isA<SubmissionRefused>());
      expect(cooldown.starts, 1);
    });

    test('a 400 failure does not start the cooldown', () async {
      repository.result = const SubmissionRefused(
        SyncStatus.failedPermanent,
        'bad payload',
      );

      await useCase.submit(EmojiChoice.satisfied);

      expect(cooldown.starts, 0);
    });

    test('an empty client id is a validation error', () async {
      useCase = build(clientId: () => '   ');

      await expectLater(
        useCase.submit(EmojiChoice.satisfied),
        throwsA(
          isA<FeedbackValidationException>().having(
            (error) => error.message,
            'message',
            contains('try again'),
          ),
        ),
      );
      expect(repository.submissions, isEmpty);
      expect(cooldown.starts, 0);
    });

    test('an empty device id is a validation error', () async {
      deviceIds.value = '';

      await expectLater(
        useCase.submit(EmojiChoice.satisfied),
        throwsA(isA<FeedbackValidationException>()),
      );
      expect(repository.submissions, isEmpty);
      expect(cooldown.starts, 0);
    });

    test('validation copy never leaks internals', () async {
      useCase = build(clientId: () => '');

      await expectLater(
        useCase.submit(EmojiChoice.satisfied),
        throwsA(
          isA<FeedbackValidationException>().having(
            (error) => error.message,
            'message',
            isNot(contains('client')),
          ),
        ),
      );
    });
  });
}
