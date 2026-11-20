typedef Clock = DateTime Function();

/// Per-scope rate limiter / cooldown guard to prevent button-mashing
/// or spam submissions while keeping separate items independent.
class CooldownService {
  static const Duration feedbackCooldown = Duration(seconds: 5);

  CooldownService({
    this.cooldownDuration = const Duration(seconds: 15),
    Clock? clock,
  }) : assert(cooldownDuration > Duration.zero, 'cooldownDuration must be > 0'),
       _clock = clock ?? DateTime.now;

  final Duration cooldownDuration;
  final Clock _clock;
  final Map<String, DateTime> _lastSubmittedAt = {};

  static const String feedbackScope = 'feedback';
  static const String ratingScope = 'rating';

  static String ratingProjectScope(String projectId) => 'rating:$projectId';

  void recordSubmission(String scope) {
    _lastSubmittedAt[scope] = _clock().toUtc();
  }

  Duration remaining(String scope) {
    final last = _lastSubmittedAt[scope];
    if (last == null) {
      return Duration.zero;
    }
    final elapsed = _clock().toUtc().difference(last);
    final left = cooldownDuration - elapsed;
    return left > Duration.zero ? left : Duration.zero;
  }

  bool isCoolingDown(String scope) => remaining(scope) > Duration.zero;

  void clear(String scope) {
    _lastSubmittedAt.remove(scope);
  }
}
