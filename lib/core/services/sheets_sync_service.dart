import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/showcase_config.dart';
import '../database/app_database.dart';

class SyncReport {
  const SyncReport({
    required this.syncedFeedback,
    required this.syncedRatings,
    required this.failedCount,
  });

  const SyncReport.empty()
    : syncedFeedback = 0,
      syncedRatings = 0,
      failedCount = 0;

  final int syncedFeedback;
  final int syncedRatings;
  final int failedCount;

  int get totalSynced => syncedFeedback + syncedRatings;
}

/// Pushes unsynced local Drift records to a Google Apps Script webhook
/// and marks acknowledged records as synced.
class SheetsSyncService {
  SheetsSyncService({
    required AppDatabase database,
    http.Client? httpClient,
    String? webhookUrl,
  }) : _db = database,
       _http = httpClient ?? http.Client(),
       _webhookUrl = webhookUrl ?? ShowcaseConfig.googleSheetsWebhookUrl;

  final AppDatabase _db;
  final http.Client _http;
  final String _webhookUrl;

  bool get isConfigured => _webhookUrl.trim().startsWith('https://');

  Future<SyncReport> syncPending() async {
    if (!isConfigured) {
      return const SyncReport.empty();
    }

    final pendingFeedback = await _db.getUnsyncedFeedback();
    final pendingRatings = await _db.getUnsyncedRatings();

    if (pendingFeedback.isEmpty && pendingRatings.isEmpty) {
      return const SyncReport.empty();
    }

    final okFeedbackIds = <String>[];
    var failedCount = 0;

    for (final item in pendingFeedback) {
      final sent = await _postPayload({
        'type': 'feedback',
        'id': item.eventId,
        'deviceId': item.deviceId,
        'sentiment': item.sentiment,
        'note': item.note,
        'timestamp': item.createdAt.toIso8601String(),
      });
      if (sent) {
        okFeedbackIds.add(item.eventId);
      } else {
        failedCount++;
      }
    }

    if (okFeedbackIds.isNotEmpty) {
      await _db.markFeedbackSynced(okFeedbackIds);
    }

    final okRatingIds = <String>[];
    for (final item in pendingRatings) {
      final sent = await _postPayload({
        'type': 'rating',
        'id': item.eventId,
        'deviceId': item.deviceId,
        'projectId': item.projectId,
        'projectTitle': item.projectTitle,
        'score': item.score,
        'timestamp': item.createdAt.toIso8601String(),
      });
      if (sent) {
        okRatingIds.add(item.eventId);
      } else {
        failedCount++;
      }
    }

    if (okRatingIds.isNotEmpty) {
      await _db.markRatingsSynced(okRatingIds);
    }

    return SyncReport(
      syncedFeedback: okFeedbackIds.length,
      syncedRatings: okRatingIds.length,
      failedCount: failedCount,
    );
  }

  Future<bool> _postPayload(Map<String, Object?> payload) async {
    try {
      final uri = Uri.parse(_webhookUrl.trim());
      final response = await _http
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 8));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }
}
