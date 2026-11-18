import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/domain/entities/emoji_choice.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/widgets/emoji_picker.dart';
import 'package:ucstgo_showcase_flutter_app/main.dart';

/// Temporary preview checkpoint (I19 → I24): the app boots into the real
/// `EmojiPicker`, and a tap updates the on-screen echo. Proves the wiring
/// in `main.dart`, not the widget contract (that lives in the picker gate).
void main() {
  testWidgets('app boots into the interactive picker preview',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    expect(find.text('How was your visit?'), findsOneWidget);
    expect(find.byType(EmojiPicker), findsOneWidget);
    expect(find.text('Nothing selected yet'), findsOneWidget);

    await tester.tap(
      find.byKey(EmojiFace.canvasKeyFor(EmojiChoice.satisfied)),
    );
    await tester.pump();

    expect(find.text('You picked: Loved it'), findsOneWidget);
  });
}
