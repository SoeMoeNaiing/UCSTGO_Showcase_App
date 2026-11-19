import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/models/sync_status.dart';
import 'package:ucstgo_showcase_flutter_app/repositories/feedback_local_datasource.dart';
import 'package:ucstgo_showcase_flutter_app/database/app_database.dart';
import 'package:ucstgo_showcase_flutter_app/models/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/models/feedback.dart';

/// Iteration 10 — FeedbackLocalDataSource gate (PROJECT_PROCESS.md §6.4, §6.6).
///
/// Proves the queue surface the repository and sync engine depend on:
/// durable insert, FIFO pending with backoff deadlines, terminal status
/// transitions, attempt bookkeeping, and deletion.
void main() {
  late AppDatabase db;
  late FeedbackLocalDataSource local;
  late DateTime now;

  setUp(() {
    db = AppDatabase.withExecutor(NativeDatabase.memory());
    now = DateTime.utc(2026, 11, 18, 12);
    local = FeedbackLocalDataSource(db, now: () => now);
  });

  tearDown(() async {
    await db.close();
  });

  Feedback build({
    String client = 'client-1',
    EmojiChoice choice = EmojiChoice.satisfied,
    DateTime? at,
  }) {
    return Feedback(
      clientId: client,
      deviceId: 'device-1',
      emojiChoice: choice,
      createdAt: at ?? now,
    );
  }

  Future<PendingFeedbackData> row(String clientId) async {
    return (db.select(db.pendingFeedback)
          ..where((table) => table.clientId.equals(clientId)))
        .getSingle();
  }

  group('FeedbackLocalDataSource (§6.4, §6.6)', () {
    test('insert makes the submission immediately pending', () async {
      final feedback = build(choice: EmojiChoice.dissatisfied);

      await local.insert(feedback);

      final pending = await local.pending();
      expect(pending, hasLength(1));
      expect(pending.single.feedback, feedback);
      expect(pending.single.attempts, 0);
      expect(pending.single.feedback.createdAt.isUtc, isTrue);

      final stored = await row('client-1');
      expect(stored.syncStatus, SyncStatus.pending.wireValue);
      expect(stored.attempts, 0);
    });

    test('pending is FIFO by createdAt and honours the limit', () async {
      await local.insert(build(client: 'third', at: now.add(const Duration(minutes: 2))));
      await local.insert(build(client: 'first', at: now));
      await local.insert(build(client: 'second', at: now.add(const Duration(minutes: 1))));

      final oldestTwo = await local.pending(limit: 2);

      expect(
        oldestTwo.map((row) => row.feedback.clientId),
        ['first', 'second'],
      );
    });

    test('markSynced removes the row from pending but keeps it', () async {
      await local.insert(build());

      await local.markSynced('client-1');

      expect(await local.pending(), isEmpty);
      final stored = await row('client-1');
      expect(stored.syncStatus, SyncStatus.synced.wireValue);
      expect(stored.nextRetryAt, isNull);
    });

    test('every terminal status is persisted exhaustively', () async {
      const terminals = [
        SyncStatus.synced,
        SyncStatus.rejected,
        SyncStatus.failedPermanent,
      ];

      for (final status in terminals) {
        final clientId = 'client-${status.wireValue}';
        await local.insert(build(client: clientId));

        switch (status) {
          case SyncStatus.pending:
            fail('pending is not terminal');
          case SyncStatus.synced:
            await local.markSynced(clientId);
          case SyncStatus.rejected:
            await local.markRejected(clientId);
          case SyncStatus.failedPermanent:
            await local.markFailedPermanent(clientId);
        }

        expect((await row(clientId)).syncStatus, status.wireValue);
        expect(await local.pending(), isEmpty);
      }
    });

    test('a scheduled retry blocks pending until its deadline', () async {
      await local.insert(build());
      final retryAt = now.add(const Duration(seconds: 30));

      await local.scheduleRetry('client-1', retryAt);

      expect(await local.pending(), isEmpty);
      final stored = await row('client-1');
      expect(stored.attempts, 1);
      expect(stored.lastAttemptAt, now);
      expect(stored.nextRetryAt, retryAt);

      now = retryAt.subtract(const Duration(seconds: 1));
      expect(await local.pending(), isEmpty);

      now = retryAt;
      expect((await local.pending()).single.feedback.clientId, 'client-1');
    });

    test('each retry increments attempts', () async {
      await local.insert(build());

      await local.scheduleRetry('client-1', now.add(const Duration(seconds: 2)));
      await local.scheduleRetry('client-1', now.add(const Duration(seconds: 4)));

      expect((await row('client-1')).attempts, 2);
    });

    test('delete removes the row entirely', () async {
      await local.insert(build());

      await local.delete('client-1');

      expect(await local.pending(), isEmpty);
      expect(await db.select(db.pendingFeedback).get(), isEmpty);
    });
  });
}
