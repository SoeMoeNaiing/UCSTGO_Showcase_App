import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/theme/app_theme.dart';
import 'package:ucstgo_showcase_flutter_app/core/widgets/live_ticker_bar.dart';
import 'package:ucstgo_showcase_flutter_app/core/widgets/maximalist_backdrop.dart';
import 'package:ucstgo_showcase_flutter_app/core/widgets/university_hero_banner.dart';

void main() {
  testWidgets(
    'renders MaximalistBackdrop, UniversityHeroBanner, and LiveTickerBar',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const MaximalistBackdrop(
            child: Column(
              children: [
                UniversityHeroBanner(
                  imageUrl: 'https://invalid.example/none.png',
                ),
                Spacer(),
                LiveTickerBar(items: ['TEST TICKER']),
              ],
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(MaximalistBackdrop), findsOneWidget);
      expect(find.byType(UniversityHeroBanner), findsOneWidget);
      expect(find.text('TEST TICKER'), findsWidgets);
    },
  );
}
