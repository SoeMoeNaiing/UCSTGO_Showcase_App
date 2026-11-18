import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/feedback/presentation/screens/feedback_preview_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppTheme.loadFonts();
  runApp(const ProviderScope(child: MyApp()));
}

/// Root app. The real router/shell arrives with `FeedbackScreen` at
/// Iteration 24; until then the app boots into the temporary preview
/// harness so the interactive picker can be exercised on a phone.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UCSTGO Showcase Kiosk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const FeedbackPreviewScreen(),
    );
  }
}
