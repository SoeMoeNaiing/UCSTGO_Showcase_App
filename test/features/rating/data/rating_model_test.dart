import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/data/models/rating_model.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/domain/entities/rating.dart';

/// Iteration 28 — RatingModel wire contract (§6.1).
void main() {
  Rating build() => Rating(
        clientId: 'client-1',
        deviceId: 'device-1',
        projectId: 'campus-navigator',
        score: 4,
        createdAt: DateTime.utc(2026, 11, 19, 10),
      );

  group('RatingModel (§6.1)', () {
    test('toJson is exactly the four client-supplied keys', () {
      expect(RatingModel.fromRating(build()).toJson(), {
        'client_id': 'client-1',
        'device_id': 'device-1',
        'project_id': 'campus-navigator',
        'score': 4,
      });
    });

    test('fromJson is strict about ids and score range', () {
      final base = RatingModel.fromRating(build()).toJson();
      expect(RatingModel.fromJson(base), RatingModel.fromRating(build()));

      expect(
        () => RatingModel.fromJson({...base, 'score': 6}),
        throwsFormatException,
      );
      expect(
        () => RatingModel.fromJson({...base, 'project_id': ''}),
        throwsFormatException,
      );
      expect(
        () => RatingModel.fromJson({...base, 'client_id': null}),
        throwsFormatException,
      );
    });

    test('toRating takes the local UTC visit time', () {
      final localTime = DateTime(2026, 11, 19, 12);
      final rating = RatingModel.fromRating(build())
          .toRating(createdAt: localTime);

      expect(rating.createdAt, localTime.toUtc());
      expect(rating.createdAt.isUtc, isTrue);
      expect(rating.projectId, 'campus-navigator');
    });
  });
}
