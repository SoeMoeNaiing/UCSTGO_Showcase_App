import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/kiosk_scaffold.dart';
import '../../domain/entities/emoji_choice.dart';
import '../widgets/emoji_picker.dart';

/// **Temporary** phone preview harness — added after Iteration 19, deleted
/// at Iteration 24 when the real `FeedbackScreen` + router land.
///
/// Its only job is to put the interactive `EmojiPicker` on a real device
/// with `flutter run` before the full feedback flow exists. It is
/// deliberately inert: a selection is echoed on screen; nothing is saved,
/// submitted, or synced.
class FeedbackPreviewScreen extends StatefulWidget {
  const FeedbackPreviewScreen({super.key});

  @override
  State<FeedbackPreviewScreen> createState() => _FeedbackPreviewScreenState();
}

class _FeedbackPreviewScreenState extends State<FeedbackPreviewScreen> {
  EmojiChoice? _lastSelected;

  void _select(EmojiChoice choice) {
    setState(() => _lastSelected = choice);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _lastSelected;

    return KioskScaffold(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'How was your visit?',
                textAlign: TextAlign.center,
                style: AppTypography.headline.copyWith(
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Tap a face — this is the real picker.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              EmojiPicker(onSelected: _select),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                selected == null
                    ? 'Nothing selected yet'
                    : 'You picked: ${EmojiFace.visibleLabelFor(selected)}',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.inkPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Preview harness · full flow at I24',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.inkSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
