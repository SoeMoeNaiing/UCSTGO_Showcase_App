import '../models/rating.dart';

/// Wire DTO for one rating — the exact client-supplied keys of the
/// `submit-rating` contract (§6.1).
///
/// `created_at` is assigned by the database and `ip_hash` is server-derived,
/// so neither is sent. Parsing is strict rather than coercing bad stats.
final class RatingModel {
  const RatingModel({
    required this.clientId,
    required this.deviceId,
    required this.projectId,
    required this.score,
  });

  factory RatingModel.fromRating(Rating rating) => RatingModel(
        clientId: rating.clientId,
        deviceId: rating.deviceId,
        projectId: rating.projectId,
        score: rating.score,
      );

  factory RatingModel.fromJson(Map<String, Object?> json) {
    final clientId = json['client_id'];
    if (clientId is! String || clientId.trim().isEmpty) {
      throw const FormatException('client_id is required');
    }
    final deviceId = json['device_id'];
    if (deviceId is! String || deviceId.trim().isEmpty) {
      throw const FormatException('device_id is required');
    }
    final projectId = json['project_id'];
    if (projectId is! String || projectId.trim().isEmpty) {
      throw const FormatException('project_id is required');
    }
    final score = json['score'];
    if (score is! int || score < 1 || score > 5) {
      throw const FormatException('score must be 1–5');
    }

    return RatingModel(
      clientId: clientId,
      deviceId: deviceId,
      projectId: projectId,
      score: score,
    );
  }

  final String clientId;
  final String deviceId;
  final String projectId;
  final int score;

  /// Exact wire payload — four keys, no more.
  Map<String, Object?> toJson() => {
        'client_id': clientId,
        'device_id': deviceId,
        'project_id': projectId,
        'score': score,
      };

  /// Rehydrates the entity with the local row's UTC visit time.
  Rating toRating({required DateTime createdAt}) => Rating(
        clientId: clientId,
        deviceId: deviceId,
        projectId: projectId,
        score: score,
        createdAt: createdAt.toUtc(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RatingModel &&
          other.clientId == clientId &&
          other.deviceId == deviceId &&
          other.projectId == projectId &&
          other.score == score;

  @override
  int get hashCode => Object.hash(clientId, deviceId, projectId, score);

  @override
  String toString() =>
      'RatingModel(clientId: $clientId, projectId: $projectId, score: $score)';
}
