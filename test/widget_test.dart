import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/app.dart';
import 'package:ucstgo_showcase_flutter_app/features/feedback/presentation/widgets/emoji_picker.dart';

/// Smoke test for the real app root (I24): ProviderScope + KioskApp boot
/// straight into the `/feedback` route and show the picker.
void main() {
  testWidgets('app boots into the feedback route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: KioskApp()));
    await tester.pump();

    expect(find.byType(EmojiPicker), findsOneWidget);
    expect(find.text('How was your visit?'), findsOneWidget);
  });
}
