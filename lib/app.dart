import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root widget: theme + declarative router (§4.1, §10.6).
///
/// The `ProviderScope` is installed by `main()` so tests can inject overrides
/// around this widget without changing its constructor.
class KioskApp extends StatelessWidget {
  const KioskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'UCSTGO Showcase Kiosk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: appRouter,
    );
  }
}
