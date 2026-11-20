import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/showcase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

const _svgStarSolid = '''
<svg viewBox="0 0 24 24" fill="currentColor" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2.5l2.95 6.08 6.7.97-4.85 4.72 1.15 6.68L12 17.77l-5.95 3.18 1.14-6.68L2.35 9.55l6.7-.97L12 2.5z"/>
</svg>
''';

const _svgTrophy = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" xmlns="http://www.w3.org/2000/svg">
  <path d="M6 4h12v5a6 6 0 0 1-12 0V4z"/>
  <path d="M6 6H3a2 2 0 0 0 0 4h3M18 6h3a2 2 0 0 1 0 4h-3"/>
  <path d="M12 15v4M8 21h8"/>
</svg>
''';

const _svgDoodleNodeGraph = '''
<svg viewBox="0 0 180 120" fill="none" stroke="currentColor" stroke-width="1.6" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="30" r="10"/>
  <circle cx="142" cy="28" r="10"/>
  <circle cx="88" cy="88" r="12"/>
  <path d="M41 34l37 45M133 35L98 78M42 30h90" stroke-dasharray="4 4"/>
  <path d="M18 104c18-10 34 10 52 0" stroke-linecap="round"/>
</svg>
''';

const _svgDoodleBraces = '''
<svg viewBox="0 0 140 120" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" xmlns="http://www.w3.org/2000/svg">
  <path d="M44 18c-12 0-16 6-16 18v12c0 8-6 12-12 12 6 0 12 4 12 12v14c0 12 4 18 16 18"/>
  <path d="M96 18c12 0 16 6 16 18v12c0 8 6 12 12 12-6 0-12 4-12 12v14c0 12-4 18-16 18"/>
  <circle cx="62" cy="60" r="2.5" fill="currentColor"/>
  <circle cx="78" cy="60" r="2.5" fill="currentColor"/>
</svg>
''';

class CsDoodleLandingScreen extends ConsumerWidget {
  const CsDoodleLandingScreen({
    super.key,
    this.feedbackRoute = '/feedback',
    this.ratingRoute = '/showcase',
  });

  final String feedbackRoute;
  final String ratingRoute;

  static const List<String> _csCodeLines = [
    'fn schedule_fcfs(procs: &[Process]) -> Vec<Metrics> {',
    'SELECT project_id, AVG(score) FROM project_ratings GROUP BY project_id;',
    'while (frame_ptr != nullptr) { page_table.lru_touch(frame_ptr); }',
    'async def sync_sheets_queue(db: AppDatabase) -> SyncReport:',
    'if (!cooldown.isCoolingDown("rating:\$id")) { emit_rating_event(); }',
    'DFS(u): for v in adj[u]: if !visited[v]: rank[v] = rank[u] + 1;',
  ];

  Future<List<({ShowcaseProject project, double avg, int count})>>
  _loadTopBuilds(AppDatabase db, List<ShowcaseProject> projects) async {
    final rows = await db.getUnsyncedRatings();
    final map = <String, List<int>>{};
    for (final r in rows) {
      (map[r.projectId] ??= []).add(r.score);
    }
    final items = [
      for (final p in projects)
        () {
          final scores = map[p.id] ?? const <int>[];
          final avg = scores.isEmpty
              ? 0.0
              : scores.fold<int>(0, (a, b) => a + b) / scores.length;
          return (project: p, avg: avg, count: scores.length);
        }(),
    ];
    items.sort((a, b) {
      final byAvg = b.avg.compareTo(a.avg);
      return byAvg != 0 ? byAvg : b.count.compareTo(a.count);
    });
    return items.take(3).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(showcaseProjectsProvider);
    final db = ref.watch(appDatabaseProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF070A12),
      body: Stack(
        children: [
          // Layer 1: Continuous CS & Code stream
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.14,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _csCodeLines.length; i++)
                      Padding(
                            padding: EdgeInsets.only(left: (i % 3) * 18.0),
                            child: Text(
                              _csCodeLines[i],
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: AppColors.electricCyan,
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .moveX(
                            begin: i.isEven ? -24 : 24,
                            end: i.isEven ? 24 : -24,
                            duration: Duration(milliseconds: 5200 + i * 650),
                            curve: Curves.easeInOutSine,
                          ),
                  ],
                ),
              ),
            ),
          ),

          // Layer 2: Animated CS SVG doodles
          Positioned(
            top: 64,
            right: 12,
            child: IgnorePointer(
              child:
                  SvgPicture.string(
                        _svgDoodleNodeGraph,
                        width: 150,
                        colorFilter: ColorFilter.mode(
                          AppColors.electricCyan.withValues(alpha: 0.28),
                          BlendMode.srcIn,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .rotate(begin: -0.04, end: 0.04, duration: 2800.ms)
                      .moveY(begin: -6, end: 6, duration: 2400.ms),
            ),
          ),
          Positioned(
            bottom: 150,
            left: 8,
            child: IgnorePointer(
              child:
                  SvgPicture.string(
                        _svgDoodleBraces,
                        width: 120,
                        colorFilter: ColorFilter.mode(
                          AppColors.solarGold.withValues(alpha: 0.24),
                          BlendMode.srcIn,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: 8, end: -8, duration: 3100.ms),
            ),
          ),

          // Layer 3: Minimal content + Leaderboard + Single FEEDBACK button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'CS // SHOWCASE',
                    style: textTheme.labelLarge?.copyWith(
                      fontFamily: 'monospace',
                      color: AppColors.electricCyan,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Build Log & Standings',
                    style: textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Minimal Leaderboard card (glass surface, no gradients)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFF101726).withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.string(
                              _svgTrophy,
                              width: 16,
                              height: 16,
                              colorFilter: const ColorFilter.mode(
                                AppColors.solarGold,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'TOP RANKED',
                              style: textTheme.labelLarge?.copyWith(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => context.go(ratingRoute),
                              child: Text(
                                'RATINGS ->',
                                style: textTheme.labelLarge?.copyWith(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: AppColors.electricCyan,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FutureBuilder<
                          List<
                            ({ShowcaseProject project, double avg, int count})
                          >
                        >(
                          future: _loadTopBuilds(db, projects),
                          builder: (context, snap) {
                            final rows = snap.data ?? const [];
                            if (rows.isEmpty) {
                              return const Text(
                                'No ratings recorded yet.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              );
                            }
                            return Column(
                              children: [
                                for (var i = 0; i < rows.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '#0${i + 1}',
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            color: AppColors.solarGold,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            rows[i].project.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SvgPicture.string(
                                          _svgStarSolid,
                                          width: 13,
                                          height: 13,
                                          colorFilter: const ColorFilter.mode(
                                            AppColors.solarGold,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          rows[i].count == 0
                                              ? '0.0'
                                              : rows[i].avg.toStringAsFixed(1),
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Only button on landing page: FEEDBACK -> then routes to project rating
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.electricCyan,
                      foregroundColor: AppColors.voidBlack,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => context.go(feedbackRoute),
                    child: const Text(
                      'FEEDBACK',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
