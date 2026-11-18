import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/data/datasources/feedback_remote_datasource.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/data/models/feedback_model.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/feedback.dart';

/// Iteration 15 — wire DTO + §6.6 outcome table.
///
/// Locks the payload to exactly the three keys the Edge Function accepts and
/// proves every HTTP status maps to one queue outcome. No network is touched.
void main() {
  final createdAt = DateTime.utc(2026, 11, 18, 12);
  final feedback = Feedback(
    clientId: '11111111-1111-4111-8111-111111111111',
    deviceId: '22222222-2222-4222-8222-222222222222',
    emojiChoice: EmojiChoice.satisfied,
    createdAt: createdAt,
  );
  final model = FeedbackModel.fromFeedback(feedback);

  group('FeedbackModel (§6.2 payload)', () {
    test('toJson emits exactly the three client-supplied keys', () {
      expect(model.toJson(), {
        'client_id': feedback.clientId,
        'device_id': feedback.deviceId,
        'emoji_choice': 'satisfied',
      });
      expect(
        model.toJson().keys.toSet(),
        {'client_id', 'device_id', 'emoji_choice'},
        reason: 'ip_hash is server-derived; created_at is assigned by the DB',
      );
    });

    test('round-trips entity → JSON → entity', () {
      final restored = FeedbackModel.fromJson(model.toJson())
          .toFeedback(createdAt: createdAt);

      expect(restored, feedback);
    });

    test('every documented emoji wire value parses back', () {
      for (final choice in EmojiChoice.values) {
        final json = {
          'client_id': 'c-1',
          'device_id': 'd-1',
          'emoji_choice': choice.wireValue,
        };

        expect(FeedbackModel.fromJson(json).emojiChoice, choice);
      }
    });

    test('fromJson ignores extra server fields', () {
      final json = {
        ...model.toJson(),
        'ip_hash': 'server-derived',
        'created_at': '2026-11-18T12:00:00Z',
      };

      expect(FeedbackModel.fromJson(json), model);
    });

    test('fromJson rejects missing or blank identifiers', () {
      final base = model.toJson();

      expect(
        () => FeedbackModel.fromJson({...base}..remove('client_id')),
        throwsFormatException,
      );
      expect(
        () => FeedbackModel.fromJson({...base, 'client_id': ''}),
        throwsFormatException,
      );
      expect(
        () => FeedbackModel.fromJson({...base}..remove('device_id')),
        throwsFormatException,
      );
      expect(
        () => FeedbackModel.fromJson({...base, 'device_id': '   '}),
        throwsFormatException,
      );
    });

    test('fromJson rejects a missing or unknown emoji choice', () {
      final base = model.toJson();

      expect(
        () => FeedbackModel.fromJson({...base}..remove('emoji_choice')),
        throwsFormatException,
      );
      expect(
        () => FeedbackModel.fromJson({...base, 'emoji_choice': 'ecstatic'}),
        throwsFormatException,
      );
    });

    test('toFeedback normalizes the local timestamp to UTC', () {
      final localTime = DateTime(2026, 11, 18, 12);

      final restored = model.toFeedback(createdAt: localTime);

      expect(restored.createdAt.isUtc, isTrue);
      expect(restored.createdAt, localTime.toUtc());
    });

    test('value equality includes both identifiers and the choice', () {
      expect(model, FeedbackModel.fromFeedback(feedback));
      expect(model.hashCode, FeedbackModel.fromFeedback(feedback).hashCode);
      expect(
        model,
        isNot(
          const FeedbackModel(
            clientId: '11111111-1111-4111-8111-111111111111',
            deviceId: 'different-device',
            emojiChoice: EmojiChoice.satisfied,
          ),
        ),
      );
    });
  });

  group('mapHttpStatus (§6.6)', () {
    test('2xx and replay 409 are success', () {
      for (final status in [200, 201, 204, 409]) {
        expect(
          mapHttpStatus(status),
          RemoteOutcome.success,
          reason: 'status $status',
        );
      }
    });

    test('429 is a terminal rejection', () {
      expect(mapHttpStatus(429), RemoteOutcome.rejected);
    });

    test('400 and other 4xx are terminal invalid', () {
      for (final status in [400, 401, 403, 404, 422]) {
        expect(
          mapHttpStatus(status),
          RemoteOutcome.invalid,
          reason: 'status $status cannot be fixed by retrying',
        );
      }
    });

    test('5xx is a retryable server error', () {
      for (final status in [500, 502, 503, 599]) {
        expect(
          mapHttpStatus(status),
          RemoteOutcome.serverError,
          reason: 'status $status',
        );
      }
    });

    test('redirects and unexpected statuses are retryable transport failures',
        () {
      for (final status in [100, 302, 0, -1, 600, 999]) {
        expect(
          mapHttpStatus(status),
          RemoteOutcome.networkFailure,
          reason: 'status $status',
        );
      }
    });
  });

  group('UnavailableFeedbackRemoteDataSource (§6.4)', () {
    test('always reports networkFailure and never throws', () async {
      const remote = UnavailableFeedbackRemoteDataSource();

      expect(await remote.submit(model), RemoteOutcome.networkFailure);
    });
  });
}
