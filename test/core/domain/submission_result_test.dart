import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/models/submission_result.dart';
import 'package:ucstgo_showcase_flutter_app/models/sync_status.dart';

/// Iteration 8 — SubmissionResult contract (PROJECT_PROCESS.md §6.4–§6.6).
///
/// Describes a result the same way the UI/controller will, via an
/// exhaustive `switch` — if a third variant is ever added, this test stops
/// compiling until every branch is handled.
String describe(SubmissionResult result) => switch (result) {
      SubmissionAccepted(:final status) => 'accepted:${status.wireValue}',
      SubmissionRefused(:final status) => 'refused:${status.wireValue}',
    };

void main() {
  group('SubmissionResult (§6.4–§6.6)', () {
    test('accepted covers exactly pending and synced', () {
      expect(
        describe(const SubmissionAccepted(SyncStatus.pending)),
        'accepted:pending',
      );
      expect(
        describe(const SubmissionAccepted(SyncStatus.synced)),
        'accepted:synced',
      );
    });

    test('refused covers exactly rejected and failedPermanent', () {
      final rateLimited = SubmissionRefused(
        SyncStatus.rejected,
        'rate limit exceeded',
      );
      final malformed = SubmissionRefused(
        SyncStatus.failedPermanent,
        'invalid payload',
      );

      expect(describe(rateLimited), 'refused:rejected');
      expect(describe(malformed), 'refused:failed_permanent');
      expect(rateLimited.reason, 'rate limit exceeded');
    });

    test('invalid status/variant combinations fail fast', () {
      expect(
        () => SubmissionAccepted(SyncStatus.rejected),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => SubmissionAccepted(SyncStatus.failedPermanent),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => SubmissionRefused(SyncStatus.pending, 'nope'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => SubmissionRefused(SyncStatus.synced, 'nope'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('status is exposed on both variants', () {
      expect(const SubmissionAccepted(SyncStatus.synced).status,
          SyncStatus.synced);
      expect(
        SubmissionRefused(SyncStatus.rejected, 'x').status,
        SyncStatus.rejected,
      );
    });
  });
}
