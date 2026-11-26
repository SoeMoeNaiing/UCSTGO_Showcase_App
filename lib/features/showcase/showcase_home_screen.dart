import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../feedback/feedback_controller.dart';
import '../../core/widgets/quick_feedback_modal.dart';
import '../../core/services/cooldown_service.dart';
import '../../core/controllers/kiosk_idle_controller.dart';

import '../../core/database/app_database.dart';
import '../../core/providers/showcase_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

const _svgStar = '''
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

const _svgArrowRight = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
  <path d="M5 12h14"/>
  <path d="m13 6 6 6-6 6"/>
</svg>
''';

const _svgSparkPulse = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
  <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/>
  <path d="M8 9h8M8 13h5"/>
</svg>
''';

const _svgVideoPlay = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
  <rect x="2" y="4" width="20" height="16" rx="3"/>
  <polygon points="10,8.5 16,12 10,15.5" fill="currentColor"/>
</svg>
''';

const _svgBookmarkLater = '''
<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" xmlns="http://www.w3.org/2000/svg">
  <path d="M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z"/>
  <path d="M12 7v6M9 10h6"/>
</svg>
''';

const _svgGraphDoodle = '''
<svg viewBox="0 0 180 120" fill="none" stroke="currentColor" stroke-width="1.6" xmlns="http://www.w3.org/2000/svg">
  <circle cx="32" cy="30" r="10"/>
  <circle cx="142" cy="28" r="10"/>
  <circle cx="88" cy="88" r="12"/>
  <path d="M41 34l37 45M133 35L98 78M42 30h90" stroke-dasharray="4 4"/>
  <path d="M18 104c18-10 34 10 52 0" stroke-linecap="round"/>
</svg>
''';

const _svgBracesDoodle = '''
<svg viewBox="0 0 140 120" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" xmlns="http://www.w3.org/2000/svg">
  <path d="M44 18c-12 0-16 6-16 18v12c0 8-6 12-12 12 6 0 12 4 12 12v14c0 12 4 18 16 18"/>
  <path d="M96 18c12 0 16 6 16 18v12c0 8 6 12 12 12-6 0-12 4-12 12v14c0 12-4 18-16 18"/>
  <circle cx="62" cy="60" r="2.5" fill="currentColor"/>
  <circle cx="78" cy="60" r="2.5" fill="currentColor"/>
</svg>
''';

const _svgBinaryTreeDoodle = '''
<svg viewBox="0 0 160 110" fill="none" stroke="currentColor" stroke-width="1.6" xmlns="http://www.w3.org/2000/svg">
  <circle cx="80" cy="20" r="9"/>
  <circle cx="44" cy="58" r="9"/>
  <circle cx="116" cy="58" r="9"/>
  <circle cx="26" cy="94" r="7"/>
  <circle cx="62" cy="94" r="7"/>
  <path d="M73 27L50 51M87 27l23 24M39 66l-10 21M49 66l10 21"/>
</svg>
''';

class _ShowcaseVideoItem {
  const _ShowcaseVideoItem({
    required this.id,
    required this.title,
    required this.tag,
    required this.duration,
    required this.accent,
  });

  final String id;
  final String title;
  final String tag;
  final String duration;
  final Color accent;
}

const List<_ShowcaseVideoItem> _showcaseVideos = [
  _ShowcaseVideoItem(
    id: 'vid_reel_01',
    title: 'Exhibition Highlights Reel',
    tag: 'REEL',
    duration: '01:24',
    accent: AppColors.electricCyan,
  ),
  _ShowcaseVideoItem(
    id: 'vid_booth_02',
    title: 'Live Booth Demos & Walkthrough',
    tag: 'DEMO',
    duration: '02:40',
    accent: AppColors.acidLime,
  ),
];

class ShowcaseHomeScreen extends ConsumerStatefulWidget {
  const ShowcaseHomeScreen({super.key});

  @override
  ConsumerState<ShowcaseHomeScreen> createState() => _ShowcaseHomeScreenState();
}

class _ShowcaseHomeScreenState extends ConsumerState<ShowcaseHomeScreen> {
  bool _pressingCta = false;
  final Set<String> _watchLaterIds = <String>{};

  static const List<String> _csSnippets = [
    'cpu_sched::hrrn(ready_queue, quantum_ms: 16);',
    'SELECT project_id, AVG(score) FROM project_ratings GROUP BY project_id;',
    'page_table.replace_lru(fault_addr: 0x004F_A200);',
    'sync_queue.flush_pending(webhook_url).await?;',
    'if (!cooldown.is_active(scope)) { commit_rating(); }',
    'graph.topo_sort(|node| emit_dag_step(node));',
    'banker_state.is_safe(available, max_claim, allocation);',
  ];

  void _toggleWatchLater(String id) {
    setState(() {
      if (_watchLaterIds.contains(id)) {
        _watchLaterIds.remove(id);
      } else {
        _watchLaterIds.add(id);
      }
    });
  }

  Future<List<({ShowcaseProject project, double avg, int count})>>
  _loadTopStandings(AppDatabase db, List<ShowcaseProject> projects) async {
    final ratings = await db.getUnsyncedRatings();
    final grouped = <String, List<int>>{};
    for (final r in rowsOrEmpty(ratings)) {
      (grouped[r.projectId] ??= []).add(r.score);
    }

    final ranked = [
      for (final p in projects)
        () {
          final scores = grouped[p.id] ?? const <int>[];
          final avg = scores.isEmpty
              ? 0.0
              : scores.fold<int>(0, (a, b) => a + b) / scores.length;
          return (project: p, avg: avg, count: scores.length);
        }(),
    ];

    ranked.sort((a, b) {
      final byAvg = b.avg.compareTo(a.avg);
      return byAvg != 0 ? byAvg : b.count.compareTo(a.count);
    });
    return ranked.take(3).toList();
  }

  List<T> rowsOrEmpty<T>(List<T> list) => list;

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(showcaseProjectsProvider);
    final db = ref.watch(appDatabaseProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFF070A12),
      body: Stack(
        children: [
          // Flowing CS & algorithm code stream
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.14,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < _csSnippets.length; i++)
                      Padding(
                            padding: EdgeInsets.only(left: (i % 3) * 16.0),
                            child: Text(
                              _csSnippets[i],
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
                            begin: i.isEven ? -26 : 26,
                            end: i.isEven ? 26 : -26,
                            duration: Duration(milliseconds: 5000 + i * 600),
                            curve: Curves.easeInOutSine,
                          ),
                  ],
                ),
              ),
            ),
          ),

          // Animated SVG CS doodles
          Positioned(
            top: 56,
            right: 10,
            child: IgnorePointer(
              child:
                  SvgPicture.string(
                        _svgGraphDoodle,
                        width: 145,
                        colorFilter: ColorFilter.mode(
                          AppColors.electricCyan.withValues(alpha: 0.25),
                          BlendMode.srcIn,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .rotate(begin: -0.04, end: 0.04, duration: 2800.ms)
                      .moveY(begin: -6, end: 6, duration: 2400.ms),
            ),
          ),
          Positioned(
            bottom: 84,
            left: 10,
            child: IgnorePointer(
              child:
                  SvgPicture.string(
                        _svgBracesDoodle,
                        width: 118,
                        colorFilter: ColorFilter.mode(
                          AppColors.solarGold.withValues(alpha: 0.22),
                          BlendMode.srcIn,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: 7, end: -7, duration: 3100.ms),
            ),
          ),
          Positioned(
            bottom: 68,
            right: 16,
            child: IgnorePointer(
              child:
                  SvgPicture.string(
                        _svgBinaryTreeDoodle,
                        width: 128,
                        colorFilter: ColorFilter.mode(
                          AppColors.acidLime.withValues(alpha: 0.2),
                          BlendMode.srcIn,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(begin: -5, end: 5, duration: 2700.ms),
            ),
          ),

          // Foreground layout
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
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
                  'System Log & Standings',
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Minimal Frosted Glass Leaderboard
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
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
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          FutureBuilder<
                            List<
                              ({ShowcaseProject project, double avg, int count})
                            >
                          >(
                            future: _loadTopStandings(db, projects),
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
                                        vertical: 4,
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
                                            _svgStar,
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
                                                : rows[i].avg.toStringAsFixed(
                                                    1,
                                                  ),
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
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Videos & Watch Later section (ready for future video slots)
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
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
                                _svgVideoPlay,
                                width: 16,
                                height: 16,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.electricCyan,
                                  BlendMode.srcIn,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'VIDEOS // WATCH LATER QUEUE',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.electricCyan,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.electricCyan.withValues(
                                    alpha: 0.14,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.electricCyan.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'LATER (${_watchLaterIds.length})',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.electricCyan,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          for (var i = 0; i < _showcaseVideos.length; i++) ...[
                            _VideoQueueRow(
                              item: _showcaseVideos[i],
                              savedForLater: _watchLaterIds.contains(
                                _showcaseVideos[i].id,
                              ),
                              onToggleLater: () =>
                                  _toggleWatchLater(_showcaseVideos[i].id),
                            ),
                            if (i < _showcaseVideos.length - 1)
                              const SizedBox(height: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Centered magnetic FEEDBACK CTA + glowing cyber code tags around bottom
                Column(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _pressingCta = true),
                        onTapUp: (_) {
                          setState(() => _pressingCta = false);
                          final idle = KioskIdleController(
                            ref: ref,
                            timeout: const Duration(seconds: 30),
                          )..attach(context: context, isMounted: () => mounted);
                          final cooldownRemaining = ref
                              .read(cooldownServiceProvider)
                              .remaining(CooldownService.feedbackScope)
                              .inSeconds;
                          final controller = FeedbackController(ref);
                          unawaited(
                            QuickFeedbackModal.show(
                              context,
                              cooldownRemainingSeconds: cooldownRemaining,
                              onPauseIdle: idle.pause,
                              onResumeIdle: idle.resume,
                              onPingIdle: idle.ping,
                              onTriggerBackgroundSync: () => ref
                                  .read(sheetsSyncServiceProvider)
                                  .syncPending(),
                              onShowToast: (message, {required bool isSuccess}) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(message),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(
                                        milliseconds: 1500,
                                      ),
                                    ),
                                  );
                              },
                              onSubmitFeedback: ({
                                required emotion,
                                required note,
                              }) =>
                                  controller.submitQuickFeedback(
                                    sentiment: emotion.keyName,
                                    note: note,
                                    isMounted: () => context.mounted,
                                  ),
                            ).whenComplete(() {
                              controller.dispose();
                              idle.dispose();
                            }),
                          );
                        },
                        onTapCancel: () => setState(() => _pressingCta = false),
                        child:
                            AnimatedScale(
                                  scale: _pressingCta ? 0.95 : 1.0,
                                  duration: const Duration(milliseconds: 120),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 16,
                                        sigmaY: 16,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10192B)
                                              .withValues(alpha: 0.86),
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          border: Border.all(
                                            color: AppColors.electricCyan
                                                .withValues(alpha: 0.65),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.electricCyan
                                                  .withValues(alpha: 0.24),
                                              blurRadius: 28,
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 28,
                                                    vertical: 18,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.electricCyan,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SvgPicture.string(
                                                    _svgSparkPulse,
                                                    width: 20,
                                                    height: 20,
                                                    colorFilter:
                                                        const ColorFilter.mode(
                                                          AppColors.voidBlack,
                                                          BlendMode.srcIn,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    'FEEDBACK',
                                                    style: TextStyle(
                                                      fontFamily: 'monospace',
                                                      fontSize: 17,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color:
                                                          AppColors.voidBlack,
                                                      letterSpacing: 1.6,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  SvgPicture.string(
                                                        _svgArrowRight,
                                                        width: 20,
                                                        height: 20,
                                                        colorFilter:
                                                            const ColorFilter.mode(
                                                              AppColors
                                                                  .voidBlack,
                                                              BlendMode.srcIn,
                                                            ),
                                                      )
                                                      .animate(
                                                        onPlay: (c) => c.repeat(
                                                          reverse: true,
                                                        ),
                                                      )
                                                      .moveX(
                                                        begin: -2,
                                                        end: 4,
                                                        duration: 750.ms,
                                                      ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'TAP TO DROP FEEDBACK & UNLOCK RATINGS',
                                              style: textTheme.labelLarge
                                                  ?.copyWith(
                                                    fontFamily: 'monospace',
                                                    fontSize: 10,
                                                    color: Colors.white70,
                                                    letterSpacing: 1.1,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scaleXY(
                                  begin: 1.0,
                                  end: 1.03,
                                  duration: 1600.ms,
                                  curve: Curves.easeInOutSine,
                                ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _CyberCodeGlowFooter(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoQueueRow extends StatelessWidget {
  const _VideoQueueRow({
    required this.item,
    required this.savedForLater,
    required this.onToggleLater,
  });

  final _ShowcaseVideoItem item;
  final bool savedForLater;
  final VoidCallback onToggleLater;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: savedForLater
              ? item.accent.withValues(alpha: 0.55)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.tag,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: item.accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${item.duration} • Ready for stream hookup',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onToggleLater,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: savedForLater
                    ? item.accent.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: savedForLater
                      ? item.accent
                      : Colors.white.withValues(alpha: 0.14),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.string(
                    _svgBookmarkLater,
                    width: 12,
                    height: 12,
                    colorFilter: ColorFilter.mode(
                      savedForLater ? item.accent : Colors.white70,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    savedForLater ? 'QUEUED' : 'LATER',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: savedForLater ? item.accent : Colors.white70,
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

class _CyberCodeGlowFooter extends StatelessWidget {
  const _CyberCodeGlowFooter();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        const _GlowingCodeGlyph(token: '<>', color: AppColors.electricCyan),
        const _GlowingCodeGlyph(token: '</>', color: AppColors.acidLime),
        const _GlowingCodeGlyph(token: '{ feedback }', color: AppColors.solarGold),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF10192B).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.electricCyan.withValues(alpha: 0.35),
            ),
          ),
          child: const Text(
            '0xSHOW_NODE // READY',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowingCodeGlyph extends StatelessWidget {
  const _GlowingCodeGlyph({required this.token, required this.color});

  final String token;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.32),
                blurRadius: 12,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: Text(
            token,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
              shadows: [
                Shadow(color: color.withValues(alpha: 0.75), blurRadius: 8),
              ],
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 900.ms)
        .then()
        .scaleXY(
          begin: 1.0,
          end: 1.05,
          duration: 1400.ms,
          curve: Curves.easeInOutSine,
        );
  }
}