import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/services/cooldown_service.dart';

void main() {
  test('starts with zero remaining cooldown and locks after recording', () {
    var now = DateTime.utc(2026, 11, 19, 14, 0, 0);
    final cooldown = CooldownService(
      cooldownDuration: const Duration(seconds: 15),
      clock: () => now,
    );

    expect(cooldown.remaining(CooldownService.feedbackScope), Duration.zero);
    expect(cooldown.isCoolingDown(CooldownService.feedbackScope), isFalse);

    cooldown.recordSubmission(
      CooldownService.feedbackScope,
      cooldown: const Duration(seconds: 15),
    );
    expect(cooldown.isCoolingDown(CooldownService.feedbackScope), isTrue);
    expect(
      cooldown.remaining(CooldownService.feedbackScope),
      const Duration(seconds: 15),
    );

    now = now.add(const Duration(seconds: 6));
    expect(
      cooldown.remaining(CooldownService.feedbackScope),
      const Duration(seconds: 9),
    );

    now = now.add(const Duration(seconds: 10));
    expect(cooldown.remaining(CooldownService.feedbackScope), Duration.zero);
    expect(cooldown.isCoolingDown(CooldownService.feedbackScope), isFalse);
  });

  test('keeps feedback and rating cooldown scopes independent', () {
    final now = DateTime.utc(2026, 11, 19, 14, 0, 0);
    final cooldown = CooldownService(
      cooldownDuration: const Duration(seconds: 10),
      clock: () => now,
    );

    cooldown.recordSubmission(
      CooldownService.feedbackScope,
      cooldown: const Duration(seconds: 10),
    );
    expect(cooldown.isCoolingDown(CooldownService.feedbackScope), isTrue);
    expect(cooldown.isCoolingDown(CooldownService.ratingScope), isFalse);
  });
}
