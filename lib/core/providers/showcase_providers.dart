import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/feedback/feedback_screen.dart';
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
  });

  final String id;
  final String title;
  final String track;
  final String summary;
  final String team;
  final List<String> techStack;
  final Color accent;
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

final showcaseProjectsProvider = Provider<List<ShowcaseProject>>((ref) {
  return const [
    ShowcaseProject(
      id: 'proj-campus-kiosk',
      title: 'UCSTGO Interactive Showcase',
      track: 'MOBILE & UI',
      summary: 'Offline-first interactive showcase hub with local Drift SQLite persistence, Google Sheets webhook sync, and kinetic motion.',
      team: 'CS Final Year • Team Alpha',
      techStack: ['Flutter', 'Drift SQLite', 'Riverpod', 'Apps Script'],
      accent: AppColors.electricCyan,
    ),
    ShowcaseProject(
      id: 'proj-vision-lab',
      title: 'Campus Vision & Attendance AI',
      track: 'AI / ML',
      summary: 'Real-time edge computer vision pipeline for lecture hall occupancy analytics and automated lab check-ins.',
      team: 'AI Research Group • UCSTGO',
      techStack: ['Python', 'OpenCV', 'TensorFlow Lite', 'FastAPI'],
      accent: AppColors.acidLime,
    ),
    ShowcaseProject(
      id: 'proj-sys-monitor',
      title: 'Linux Kernel & Process Visualizer',
      track: 'SYSTEMS & OS',
      summary: 'Interactive CPU scheduler and memory paging simulator demonstrating FCFS, SRT, LRU, and Banker deadlock avoidance.',
      team: 'Systems Lab • Batch 2026',
      techStack: ['C++', 'Linux', 'WebSockets', 'Dart'],
      accent: AppColors.hyperCoral,
    ),
    ShowcaseProject(
      id: 'proj-smart-hostel',
      title: 'Smart Hostel & Roll-Call Hub',
      track: 'FULL-STACK',
      summary: 'Digital room allocation and nightly roll-call management across two campus residence floors with instant reporting.',
      team: 'Software Engineering Track',
      techStack: ['Java', 'MySQL', 'REST API', 'Flutter'],
      accent: AppColors.solarGold,
    ),
  ];
});

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const ShowcaseHomeScreen(),
          transitionsBuilder: (context, animation, secondary, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
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
