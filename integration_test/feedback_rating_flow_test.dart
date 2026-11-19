import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ucstgo_showcase_flutter_app/main.dart' as app;
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/widgets/emoji_picker.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/widgets/rate_projects_prompt.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/widgets/thank_you_card.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/presentation/screens/rating_screen.dart';
import 'package:ucstgo_showcase_flutter_app/features/rating/presentation/widgets/rating_widget.dart';
import 'package:ucstgo_showcase_flutter_app/features/showcase/presentation/widgets/project_card.dart';
import 'package:ucstgo_showcase_flutter_app/features/showcase/presentation/widgets/project_carousel.dart';

/// Iteration 33 — real-device happy path with no backend attached.
///
/// Boots the actual `main()` (real Drift queue, real SharedPreferences,
/// unplugged remote) so both submissions queue locally. Run with:
///   flutter test integration_test -d DEVICE_ID
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('feedback then rating completes fully offline', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Feedback: picker -> thank-you -> rating prompt.
    expect(find.byType(EmojiPicker), findsOneWidget);
    await tester.tap(
      find.byKey(EmojiFace.canvasKeyFor(EmojiChoice.satisfied)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ThankYouCard), findsOneWidget);

    await tester.pump(const Duration(seconds: 2, milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.byType(RateProjectsPrompt), findsOneWidget);

    // Yes navigates into the real rating screen.
    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();
    expect(find.byType(RatingScreen), findsOneWidget);
    expect(find.byType(ProjectCarousel), findsOneWidget);

    // Pick a project, score it, submit, confirm, return to the carousel.
    await tester.tap(find.byType(ProjectCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(RatingWidget), findsOneWidget);

    final handle = tester.ensureSemantics();
    try {
      await tester.tap(find.bySemanticsLabel('Rate 4 stars'));
      await tester.pumpAndSettle();
    } finally {
      handle.dispose();
    }

    await tester.tap(
      find.descendant(
        of: find.byKey(RatingScreen.submitKey),
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(RatingScreen.confirmationKey), findsOneWidget);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(ProjectCarousel), findsOneWidget);
  });
}
