import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/feedback/feedback_screen.dart';
import '../../features/rating/project_rating_screen.dart';
import '../../features/showcase/showcase_home_screen.dart';
import '../database/app_database.dart';
import '../services/cooldown_service.dart';
import '../services/device_id_service.dart';
import '../services/sheets_sync_service.dart';
import '../theme/app_colors.dart';

class ShowcaseProject {
  const ShowcaseProject({
    required this.id,
    required this.title,
    required this.track,
    required this.summary,
    required this.team,
    required this.techStack,
    required this.accent,
    this.booth = '',
    this.imageUrl,
  });

  final String id;
  final String title;
  final String track;
  final String summary;
  final String team;
  final List<String> techStack;
  final Color accent;
  final String booth;
  final String? imageUrl;

  factory ShowcaseProject.fromRow(ShowcaseProjectRow row) {
    final parsedStack = _decodeTechStack(row.techStackJson);
    return ShowcaseProject(
      id: row.projectId,
      title: row.title,
      track: row.track,
      summary: row.summary,
      team: row.team,
      booth: row.booth,
      imageUrl: row.imageUrl,
      techStack: parsedStack,
      accent: _parseHexColor(row.accentHex),
    );
  }

  static List<String> _decodeTechStack(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return const [];
  }

  static Color _parseHexColor(String hex) {
    final cleaned = hex.trim().replaceFirst('#', '');
    if (cleaned.length == 6 || cleaned.length == 8) {
      final fullHex = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
      final value = int.tryParse(fullHex, radix: 16);
      if (value != null) {
        return Color(value);
      }
    }
    return AppColors.electricCyan;
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DeviceIdService(prefs);
});

final cooldownServiceProvider = Provider<CooldownService>((ref) {
  return CooldownService(cooldownDuration: const Duration(seconds: 15));
});

final sheetsSyncServiceProvider = Provider<SheetsSyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return SheetsSyncService(database: db);
});

/// Reactive stream of approved showcase projects stored in local SQLite.
final approvedProjectsStreamProvider = StreamProvider<List<ShowcaseProject>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchApprovedProjects().map(
    (rows) => rows.map(ShowcaseProject.fromRow).toList(),
  );
});

/// Synchronous snapshot list for screens expecting `List<ShowcaseProject>`.
final showcaseProjectsProvider = Provider<List<ShowcaseProject>>((ref) {
  final asyncProjects = ref.watch(approvedProjectsStreamProvider);
  return asyncProjects.maybeWhen(
    data: (items) => items,
    orElse: () => const [],
  );
});

/// Dynamic tracks derived from approved SQLite projects.
final activeTracksProvider = FutureProvider<List<String>>((ref) async {
  ref.watch(approvedProjectsStreamProvider);
  final db = ref.watch(appDatabaseProvider);
  return db.getActiveTracks();
});

final catalogSyncProvider = FutureProvider.autoDispose<CatalogSyncResult>((
  ref,
) async {
  final syncService = ref.watch(sheetsSyncServiceProvider);
  return syncService.pullCatalog();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(sessionRatedProjectsProvider.notifier).resetSession();
          });
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const ShowcaseHomeScreen(),
            transitionsBuilder: (context, animation, secondary, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          );
        },
      ),
      GoRoute(
        path: '/rating',
        builder: (context, state) => const ProjectRatingScreen(),
      ),
      GoRoute(
        path: '/feedback',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 300),
          child: const FeedbackScreen(),
          transitionsBuilder: (context, animation, secondary, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            );
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        ),
      ),
    ],
  );
});

class SessionRatedProjectsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  void markRated(String projectId) {
    final trimmed = projectId.trim();
    if (trimmed.isEmpty || state.contains(trimmed)) return;
    state = <String>{...state, trimmed};
  }

  void resetSession() {
    if (state.isEmpty) return;
    state = const <String>{};
  }
}

final sessionRatedProjectsProvider =
    NotifierProvider<SessionRatedProjectsNotifier, Set<String>>(
      SessionRatedProjectsNotifier.new,
    );
