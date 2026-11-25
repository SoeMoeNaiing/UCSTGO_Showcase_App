import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/showcase_providers.dart';

class KioskIdleController {
  KioskIdleController({
    required this.ref,
    this.timeout = const Duration(seconds: 30),
    this.homeRoute = '/',
  });

  final WidgetRef ref;
  final Duration timeout;
  final String homeRoute;

  Timer? _timer;
  bool _paused = false;
  BuildContext? _context;
  bool Function()? _isMounted;

  void attach({
    required BuildContext context,
    required bool Function() isMounted,
  }) {
    _context = context;
    _isMounted = isMounted;
    ping();
  }

  void ping() {
    _timer?.cancel();
    if (_paused) {
      return;
    }
    _timer = Timer(timeout, _handleTimeout);
  }

  void pause() {
    _paused = true;
    _timer?.cancel();
  }

  void resume() {
    _paused = false;
    ping();
  }

  void goHomeNow(BuildContext context) {
    _timer?.cancel();
    ref.read(sessionRatedProjectsProvider.notifier).resetSession();
    context.go(homeRoute);
  }

  void _handleTimeout() {
    final ctx = _context;
    final mounted = _isMounted;
    if (_paused || ctx == null || mounted == null || !mounted()) {
      return;
    }
    Navigator.of(ctx, rootNavigator: true).maybePop();
    ref.read(sessionRatedProjectsProvider.notifier).resetSession();
    ctx.go(homeRoute);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _context = null;
    _isMounted = null;
  }
}
