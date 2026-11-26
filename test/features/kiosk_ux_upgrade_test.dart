import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/core/widgets/quick_feedback_modal.dart';
import 'package:ucstgo_showcase_flutter_app/core/widgets/rating_momentum_widgets.dart';
import 'package:ucstgo_showcase_flutter_app/models/kiosk_emotion.dart';

void main() {
  group('QuickFeedbackModal', () {
    testWidgets('renders emotions, quick tags, and fires submit callback', (
      WidgetTester tester,
    ) async {
      KioskEmotion? submittedEmotion;
      String? submittedNote;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  QuickFeedbackModal.show(
                    context,
                    onPauseIdle: () {},
                    onResumeIdle: () {},
                    onPingIdle: () {},
                    onShowToast: (_, {required bool isSuccess}) {},
                    onTriggerBackgroundSync: () async {},
                    onSubmitFeedback: ({
                      required KioskEmotion emotion,
                      required String note,
                    }) async {
                      submittedEmotion = emotion;
                      submittedNote = note;
                      return true;
                    },
                  );
                },
                child: const Text('OPEN FEEDBACK'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN FEEDBACK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SUBMIT FEEDBACK'), findsOneWidget);

      await tester.tap(find.text('SUBMIT FEEDBACK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(submittedEmotion, isNotNull);
      expect(submittedNote, isNotNull);
    });
  });

  group('Rating momentum widgets', () {
    testWidgets('SessionProgressPill and ProjectVoteStatusBadge reflect session state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SessionProgressPill(ratedCount: 2, totalCount: 8),
                ProjectVoteStatusBadge(isRatedInSession: false),
                ProjectVoteStatusBadge(isRatedInSession: true),
              ],
            ),
          ),
        ),
      );

      expect(find.text('YOUR SESSION: 2 / 8 RATED'), findsOneWidget);
      expect(find.text('TAP TO RATE'), findsOneWidget);
      expect(find.text('RATED THIS SESSION'), findsOneWidget);
    });

    testWidgets('NextUnratedBoothBar triggers onRateNext callback', (
      WidgetTester tester,
    ) async {
      var rateNextTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextUnratedBoothBar(
              lastRatedTitle: 'Smart Hostel',
              remainingCount: 5,
              nextProjectTitle: 'Campus2Career',
              onRateNext: () => rateNextTapped = true,
              onDismiss: () {},
            ),
          ),
        ),
      );

      expect(find.text('RATED SMART HOSTEL • 5 LEFT'), findsOneWidget);
      expect(find.text('Next up: Campus2Career'), findsOneWidget);

      await tester.tap(find.text('RATE NEXT'));
      await tester.pump();

      expect(rateNextTapped, isTrue);
    });
  });
}
