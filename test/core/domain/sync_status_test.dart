import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/domain/sync_status.dart';

/// Iteration 8 — SyncStatus vocabulary (PROJECT_PROCESS.md §6.6).
void main() {
  group('SyncStatus (§6.6)', () {
    test('has exactly the four documented states', () {
      expect(SyncStatus.values, hasLength(4));
      expect(
        SyncStatus.values.map((status) => status.wireValue),
        ['pending', 'synced', 'rejected', 'failed_permanent'],
      );
    });

    test('pending is the only non-terminal state', () {
      expect(SyncStatus.pending.isTerminal, isFalse);
      expect(SyncStatus.synced.isTerminal, isTrue);
      expect(SyncStatus.rejected.isTerminal, isTrue);
      expect(SyncStatus.failedPermanent.isTerminal, isTrue);
    });

    test('wire values round-trip through JSON', () {
      for (final status in SyncStatus.values) {
        expect(SyncStatus.fromJson(status.toJson()), status);
      }
    });

    test('unknown stored values throw instead of coercing', () {
      expect(() => SyncStatus.fromJson('retrying'), throwsFormatException);
      expect(() => SyncStatus.fromJson(''), throwsFormatException);
    });
  });
}
