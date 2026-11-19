/// A visitor's 1–5 rating for one showcase project — PROCESS §6.1, §6.5.
///
/// Pure domain entity: no Flutter, no Supabase, no JSON (DTO in
/// `data/models/`, Phase 4). Like [Feedback], it carries a client-generated
/// [clientId] idempotency key created *before* the local write, so replaying
/// a sync never double-counts a rating (§6.5).
final class Rating {
  Rating({
    required this.clientId,
    required this.deviceId,
    required this.projectId,
    required this.score,
    required this.createdAt,
  })  : assert(clientId != '', 'clientId is the idempotency key — required'),
        assert(deviceId != '', 'deviceId is required (anonymous identity)'),
        assert(projectId != '', 'projectId is required'),
        assert(score >= 1 && score <= 5, 'score must be 1–5 (§6.1)'),
        assert(createdAt.isUtc, 'createdAt must be UTC (queue + server contract)');

  /// Client-generated UUID v4 — the idempotency key (§6.5).
  final String clientId;

  /// Anonymous persistent device identifier (no PII, §2.4).
  final String deviceId;

  /// Showcase project identifier (string, matches the fixture list).
  final String projectId;

  /// Star score, 1–5 inclusive (§6.1).
  final int score;

  /// When the visitor rated, in UTC.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Rating &&
            other.clientId == clientId &&
            other.deviceId == deviceId &&
            other.projectId == projectId &&
            other.score == score &&
            other.createdAt == createdAt;
  }

  @override
  int get hashCode =>
      Object.hash(clientId, deviceId, projectId, score, createdAt);

  @override
  String toString() =>
      'Rating(clientId: $clientId, projectId: $projectId, score: $score, '
      'createdAt: ${createdAt.toIso8601String()})';
}
