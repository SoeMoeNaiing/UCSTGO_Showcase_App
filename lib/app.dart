import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import './router/app_router.dart';
import './theme/theme.dart';

/// Root widget: theme + declarative router (§4.1, §10.6).
///
/// The `ProviderScope` is installed by `main()` so tests can inject overrides
/// around this widget without changing its constructor.
class KioskApp extends StatelessWidget {
  const KioskApp({super.key, this.router});

  /// Injected in tests so each one gets a fresh navigation location.
  final GoRouter? router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'UCSTGO Showcase Kiosk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router ?? appRouter,
    );
  }
}
