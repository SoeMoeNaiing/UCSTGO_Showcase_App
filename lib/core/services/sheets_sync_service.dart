import 'dart:convert';

import 'package:drift/drift.dart';
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

class CatalogSyncResult {
  const CatalogSyncResult({
    required this.ok,
    required this.upsertedCount,
    this.error,
  });

  final bool ok;
  final int upsertedCount;
  final String? error;
}

/// Pushes unsynced local Drift records to a Google Apps Script webhook
/// and pulls approved showcase projects into local SQLite storage.
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

  Future<CatalogSyncResult> pullCatalog({bool pruneMissing = true}) async {
    if (!isConfigured) {
      return const CatalogSyncResult(
        ok: false,
        upsertedCount: 0,
        error: 'Webhook URL is not configured.',
      );
    }

    try {
      final baseUri = Uri.parse(_webhookUrl.trim());
      final catalogUri = baseUri.replace(
        queryParameters: {
          ...baseUri.queryParameters,
          'action': 'projects',
        },
      );

      final response = await _http
          .get(catalogUri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return CatalogSyncResult(
          ok: false,
          upsertedCount: 0,
          error: 'HTTP ${response.statusCode}',
        );
      }

      final decoded = jsonDecode(response.body);
      final rawList = decoded is Map<String, dynamic>
          ? (decoded['projects'] as List<dynamic>? ?? const [])
          : (decoded is List<dynamic> ? decoded : const []);

      final companions = <ShowcaseProjectsCompanion>[];
      for (var i = 0; i < rawList.length; i++) {
        final item = rawList[i];
        if (item is! Map<String, dynamic>) {
          continue;
        }
        final id = (item['id'] ?? item['projectId'] ?? '').toString().trim();
        final title = (item['title'] ?? '').toString().trim();
        final track = (item['track'] ?? item['category'] ?? '')
            .toString()
            .trim();
        if (id.isEmpty || title.isEmpty || track.isEmpty) {
          continue;
        }

        final approvedRaw = item['approved'];
        final approved = approvedRaw is bool
            ? approvedRaw
            : approvedRaw?.toString().toLowerCase() != 'false';
        if (!approved) {
          continue;
        }

        final rawImage = (item['imageUrl'] ?? item['image_url'] ?? '')
            .toString()
            .trim();
        final validImage = rawImage.startsWith('https://') ? rawImage : null;

        final techRaw = item['techStack'];
        final techJson = techRaw is List
            ? jsonEncode(techRaw.map((e) => e.toString()).toList())
            : (techRaw is String && techRaw.trim().startsWith('[')
                  ? techRaw.trim()
                  : '[]');

        companions.add(
          ShowcaseProjectsCompanion.insert(
            projectId: id,
            title: title,
            track: track,
            summary: Value((item['summary'] ?? '').toString().trim()),
            team: Value((item['team'] ?? '').toString().trim()),
            booth: Value((item['booth'] ?? '').toString().trim()),
            imageUrl: Value(validImage),
            techStackJson: Value(techJson),
            accentHex: Value(
              (item['accentHex'] ?? '#00F5D4').toString().trim(),
            ),
            sortOrder: Value(
              item['sortOrder'] is int ? item['sortOrder'] as int : i,
            ),
            approved: const Value(true),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      }

      await _db.upsertProjects(companions, pruneMissing: pruneMissing && rawList.isNotEmpty);
      return CatalogSyncResult(ok: true, upsertedCount: companions.length);
    } catch (e) {
      return CatalogSyncResult(
        ok: false,
        upsertedCount: 0,
        error: e.toString(),
      );
    }
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
          .timeout(const Duration(seconds: 10));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return false;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded['ok'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Seeds realistic showcase demo projects into local Drift SQLite and,
  /// when configured, posts each submission to the Apps Script webhook.
  Future<({int seededCount, int postedCount})> seedDemoProjects({
    bool postToWebhook = true,
  }) async {
    final now = DateTime.now().toUtc();
    final samples = [
      {
        'id': 'proj-demo-101',
        'title': 'Smart Campus Transit Tracker',
        'track': 'MOBILE & IOT',
        'summary':
            'Real-time shuttle and campus route tracker with offline-first caching and live stop arrival estimates.',
        'team': 'Taungoo Systems Lab',
        'booth': 'B-01',
        'imageUrl':
            'https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=1200&q=80',
        'techStack': ['Flutter', 'Dart', 'SQLite', 'MQTT'],
        'accentHex': '#00F5D4',
        'sortOrder': 1,
        'approved': true,
      },
      {
        'id': 'proj-demo-102',
        'title': 'AegisGrid Microgrid Monitor',
        'track': 'EMBEDDED & AI',
        'summary':
            'Edge telemetry dashboard forecasting solar-battery load balance and fault alerts across campus blocks.',
        'team': 'VoltCraft Collective',
        'booth': 'B-02',
        'imageUrl':
            'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?auto=format&fit=crop&w=1200&q=80',
        'techStack': ['Python', 'TensorFlow Lite', 'ESP32', 'PostgreSQL'],
        'accentHex': '#FFBE0B',
        'sortOrder': 2,
        'approved': true,
      },
      {
        'id': 'proj-demo-103',
        'title': 'CivicLedger Permit Portal',
        'track': 'WEB & CLOUD',
        'summary':
            'Streamlined local registration and document verification workflow with audit trails and instant status tracking.',
        'team': 'CloudForge Team',
        'booth': 'B-03',
        'imageUrl':
            'https://images.unsplash.com/photo-1555066931-4365d14bab8c?auto=format&fit=crop&w=1200&q=80',
        'techStack': ['TypeScript', 'Node.js', 'Docker', 'MySQL'],
        'accentHex': '#FF006E',
        'sortOrder': 3,
        'approved': true,
      },
    ];

    final companions = <ShowcaseProjectsCompanion>[];
    var postedCount = 0;

    for (var i = 0; i < samples.length; i++) {
      final item = samples[i];
      final techList = (item['techStack'] as List<String>);
      final rawImage = (item['imageUrl'] as String?)?.trim() ?? '';
      final validImage = rawImage.startsWith('https://') ? rawImage : null;

      companions.add(
        ShowcaseProjectsCompanion.insert(
          projectId: item['id']! as String,
          title: item['title']! as String,
          track: item['track']! as String,
          summary: Value(item['summary']! as String),
          team: Value(item['team']! as String),
          booth: Value(item['booth']! as String),
          imageUrl: Value(validImage),
          techStackJson: Value(jsonEncode(techList)),
          accentHex: Value(item['accentHex']! as String),
          sortOrder: Value(item['sortOrder'] as int? ?? i),
          approved: const Value(true),
          updatedAt: now,
        ),
      );

      if (postToWebhook && isConfigured) {
        final ok = await _postPayload({
          'type': 'project_submission',
          'id': item['id'],
          'title': item['title'],
          'track': item['track'],
          'summary': item['summary'],
          'team': item['team'],
          'booth': item['booth'],
          'imageUrl': validImage ?? '',
          'techStack': techList,
          'accentHex': item['accentHex'],
          'approved': false,
        });
        if (ok) postedCount++;
      }
    }

    await _db.upsertProjects(companions, pruneMissing: false);
    return (seededCount: companions.length, postedCount: postedCount);
  }

}
