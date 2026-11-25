import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/providers/showcase_providers.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const UcStgoShowcaseApp(),
    ),
  );
}

class UcStgoShowcaseApp extends ConsumerStatefulWidget {
  const UcStgoShowcaseApp({super.key});

  @override
  ConsumerState<UcStgoShowcaseApp> createState() => _UcStgoShowcaseAppState();
}

class _UcStgoShowcaseAppState extends ConsumerState<UcStgoShowcaseApp>
    with WidgetsBindingObserver {
  static const Duration _pullCooldown = Duration(seconds: 60);

  Timer? _pollTimer;
  DateTime? _lastCatalogPull;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_runSyncCycle(forcePull: true));
      _pollTimer = Timer.periodic(_pullCooldown, (_) {
        if (mounted) {
          unawaited(_runSyncCycle(forcePull: false));
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      unawaited(_runSyncCycle(forcePull: false));
    }
  }

  Future<void> _runSyncCycle({required bool forcePull}) async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final syncService = ref.read(sheetsSyncServiceProvider);
      if (!syncService.isConfigured) return;

      final now = DateTime.now();
      final cooldownElapsed = _lastCatalogPull == null ||
          now.difference(_lastCatalogPull!) >= _pullCooldown;

      if (forcePull || cooldownElapsed) {
        _lastCatalogPull = now;
        ref.invalidate(catalogSyncProvider);
        await ref.read(catalogSyncProvider.future);
      }

      await syncService.syncPending();
    } finally {
      _isSyncing = false;
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'UCSTGO Showcase',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
