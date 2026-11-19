import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/config/showcase_config.dart';
import 'package:ucstgo_showcase_flutter_app/core/theme/app_colors.dart';
import 'package:ucstgo_showcase_flutter_app/core/theme/app_theme.dart';

void main() {
  test('AppTheme.dark configures dark void scaffold and electric accents', () {
    final theme = AppTheme.dark;
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.voidBlack);
    expect(theme.colorScheme.primary, AppColors.electricCyan);
    expect(theme.colorScheme.secondary, AppColors.hyperCoral);
  });

  test('ShowcaseConfig defines valid default university image URL', () {
    expect(ShowcaseConfig.universityImageUrl, startsWith('https://'));
    expect(ShowcaseConfig.hasRemoteWebhook, isFalse);
  });
}
