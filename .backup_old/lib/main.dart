import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import './app.dart';
import './theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppTheme.loadFonts();
  runApp(const ProviderScope(child: KioskApp()));
}
