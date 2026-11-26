import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/showcase_providers.dart';
import '../../core/services/cooldown_service.dart';
import '../../core/theme/app_colors.dart';

class FeedbackController extends ChangeNotifier {
  FeedbackController(this.ref);

  final WidgetRef ref;
  final TextEditingController noteController = TextEditingController();
  final Uuid _uuid = const Uuid();

  String? _selectedReaction;
  bool _submitting = false;
  String? _statusMessage;
  Color _statusColor = AppColors.acidLime;

  String? get selectedReaction => _selectedReaction;
  bool get submitting => _submitting;
  String? get statusMessage => _statusMessage;
  Color get statusColor => _statusColor;
  bool get canSubmit => !_submitting && _selectedReaction != null;

  void selectReaction(String reactionId) {
    _selectedReaction = reactionId;
    notifyListeners();
  }

  Future<bool> submit({
    required bool Function() isMounted,
    required Future<void> Function() onSaved,
  }) async {
    final reaction = _selectedReaction;
    if (_submitting || reaction == null) {
      return false;
    }

    final cooldown = ref.read(cooldownServiceProvider);
    final remaining = cooldown.remaining(CooldownService.feedbackScope);
    if (remaining > Duration.zero) {
      _statusColor = AppColors.solarGold;
      _statusMessage =
          'WAIT ${remaining.inSeconds + 1}S BEFORE SENDING AGAIN';
      notifyListeners();
      return false;
    }

    _submitting = true;
    _statusMessage = null;
    notifyListeners();

    try {
      final db = ref.read(appDatabaseProvider);
      final deviceId = await ref
          .read(deviceIdServiceProvider)
          .getOrCreateDeviceId();

      await db.insertFeedback(
        eventId: 'fb-${_uuid.v4()}',
        deviceId: deviceId,
        sentiment: reaction,
        note: noteController.text.trim(),
      );

      cooldown.recordSubmission(
        CooldownService.feedbackScope,
        cooldown: CooldownService.feedbackCooldown,
      );
      unawaited(ref.read(sheetsSyncServiceProvider).syncPending());

      if (!isMounted()) {
        return false;
      }

      _statusColor = AppColors.acidLime;
      _statusMessage = 'FEEDBACK RECORDED.';
      notifyListeners();

      await onSaved();
      return true;
    } finally {
      _submitting = false;
      if (isMounted()) {
        notifyListeners();
      }
    }
  }

  Future<bool> submitQuickFeedback({
  required String sentiment,
  required String note,
  required bool Function() isMounted,
}) async {
  if (_submitting) return false;

  final cooldown = ref.read(cooldownServiceProvider);
  final remaining = cooldown.remaining(CooldownService.feedbackScope);
  if (remaining > Duration.zero) {
    _statusColor = AppColors.solarGold;
    _statusMessage =
        'WAIT ${remaining.inSeconds + 1}S BEFORE SENDING AGAIN';
    notifyListeners();
    return false;
  }

  _submitting = true;
  notifyListeners();

  try {
    final deviceId = await ref.read(deviceIdServiceProvider).getOrCreateDeviceId();
    final db = ref.read(appDatabaseProvider);
    final id = _uuid.v4();

    // Replace with your exact AppDatabase feedback insert call from lines 20-85:
    await db.insertFeedback(
        eventId: 'fb-${_uuid.v4()}',
        deviceId: deviceId,
      sentiment: sentiment,
      note: note,
    );

    cooldown.recordSubmission(
      CooldownService.feedbackScope,
      cooldown: CooldownService.feedbackCooldown,
    );
    unawaited(ref.read(sheetsSyncServiceProvider).syncPending());

    if (!isMounted()) return false;

    _statusColor = AppColors.acidLime;
    _statusMessage = 'FEEDBACK RECORDED';
    notifyListeners();
    return true;
  } catch (_) {
    if (!isMounted()) return false;
    _statusColor = AppColors.solarGold;
    _statusMessage = 'COULD NOT SAVE FEEDBACK';
    notifyListeners();
    return false;
  } finally {
    if (isMounted()) {
      _submitting = false;
      notifyListeners();
    }
  }
}

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }
}
