import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SessionProgressPill extends StatelessWidget {
  const SessionProgressPill({
    super.key,
    required this.ratedCount,
    required this.totalCount,
  });

  final int ratedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final hasVotes = ratedCount > 0;
    final accent = hasVotes ? const Color(0xFFA3FF12) : const Color(0xFF00E5FF);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xCC0D1322),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'YOUR SESSION: $ratedCount / $totalCount RATED',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: const Color(0xFFF5F7FF),
            ),
          ),
        ],
      ),
    );
  }
}

class ProjectVoteStatusBadge extends StatelessWidget {
  const ProjectVoteStatusBadge({
    super.key,
    required this.isRatedInSession,
    this.accentColor = const Color(0xFF00E5FF),
  });

  final bool isRatedInSession;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final badgeColor =
        isRatedInSession ? const Color(0xFFA3FF12) : accentColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRatedInSession
                ? Icons.check_circle_outline_rounded
                : Icons.star_outline_rounded,
            size: 13,
            color: badgeColor,
          ),
          const SizedBox(width: 5),
          Text(
            isRatedInSession ? 'RATED THIS SESSION' : 'TAP TO RATE',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }
}

class NextUnratedBoothBar extends StatelessWidget {
  const NextUnratedBoothBar({
    super.key,
    required this.lastRatedTitle,
    required this.remainingCount,
    required this.nextProjectTitle,
    required this.onRateNext,
    required this.onDismiss,
  });

  final String lastRatedTitle;
  final int remainingCount;
  final String nextProjectTitle;
  final VoidCallback onRateNext;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xE60D1322),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0x7300E5FF),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RATED ${lastRatedTitle.toUpperCase()} • $remainingCount LEFT',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: const Color(0xFFA3FF12),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Next up: $nextProjectTitle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF5F7FF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: onRateNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: const Color(0xFF070A12),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'RATE NEXT',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0x99F5F7FF),
                ),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
