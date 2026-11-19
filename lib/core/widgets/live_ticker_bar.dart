import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Looping horizontal showcase bar so TV/kiosk screens stay kinetic.
class LiveTickerBar extends StatefulWidget {
  const LiveTickerBar({
    super.key,
    this.items = const [
      'UCSTGO SHOWCASE',
      'LOCAL DRIFT DB ACTIVE',
      'GOOGLE SHEETS SYNC READY',
      'ANTI-SPAM COOLDOWN ENABLED',
      'PROJECT RATINGS OPEN',
    ],
  });

  final List<String> items;

  @override
  State<LiveTickerBar> createState() => _LiveTickerBarState();
}

class _LiveTickerBarState extends State<LiveTickerBar>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scroll = ScrollController();
  late final AnimationController _ticker = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _ticker.addListener(_onTick);
  }

  void _onTick() {
    if (!_scroll.hasClients) {
      return;
    }
    final maxExtent = _scroll.position.maxScrollExtent;
    if (maxExtent > 0) {
      _scroll.jumpTo((_ticker.value * maxExtent).clamp(0.0, maxExtent));
    }
  }

  @override
  void dispose() {
    _ticker.removeListener(_onTick);
    _ticker.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repeated = [...widget.items, ...widget.items, ...widget.items];
    return Container(
      height: 38,
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          top: BorderSide(color: AppColors.electricCyan, width: 1.5),
          bottom: BorderSide(color: AppColors.hyperCoral, width: 1.5),
        ),
      ),
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: repeated.length,
        separatorBuilder: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Center(
            child: Text(
              '///',
              style: AppTypography.textTheme.labelLarge?.copyWith(
                color: AppColors.hyperCoral,
              ),
            ),
          ),
        ),
        itemBuilder: (context, index) => Center(
          child: Text(
            repeated[index],
            style: AppTypography.textTheme.labelLarge?.copyWith(
              color: index.isEven ? AppColors.electricCyan : AppColors.acidLime,
            ),
          ),
        ),
      ),
    );
  }
}
