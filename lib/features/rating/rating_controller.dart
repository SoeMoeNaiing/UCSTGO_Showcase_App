import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/showcase_providers.dart';

class ProjectScoreStat {
  const ProjectScoreStat({required this.avg, required this.count});

  final double avg;
  final int count;
}

class RatingController extends ChangeNotifier {
  RatingController(this.ref);

  final WidgetRef ref;
  String _selectedTrack = 'ALL';

  String get selectedTrack => _selectedTrack;

  void selectTrack(String track) {
    if (_selectedTrack == track) {
      return;
    }
    _selectedTrack = track;
    notifyListeners();
  }

  List<String> buildTracks(List<ShowcaseProject> projects) {
    return <String>[
      'ALL',
      ...<String>{for (final p in projects) p.track},
    ];
  }

  List<ShowcaseProject> filterProjects(List<ShowcaseProject> projects) {
    if (_selectedTrack == 'ALL') {
      return projects;
    }
    return projects.where((p) => p.track == _selectedTrack).toList();
  }

  void triggerInitialSync() {
    final syncService = ref.read(sheetsSyncServiceProvider);
    unawaited(syncService.pullCatalog());
    unawaited(syncService.syncPending());
  }

  Future<Map<String, ProjectScoreStat>> loadProjectScores(
    AppDatabase db,
  ) async {
    final ratings = await db.getUnsyncedRatings();
    final grouped = <String, List<int>>{};
    for (final r in ratings) {
      (grouped[r.projectId] ??= []).add(r.score);
    }
    final result = <String, ProjectScoreStat>{};
    for (final entry in grouped.entries) {
      final sum = entry.value.fold<int>(0, (a, b) => a + b);
      result[entry.key] = ProjectScoreStat(
        avg: sum / entry.value.length,
        count: entry.value.length,
      );
    }
    return result;
  }
}
