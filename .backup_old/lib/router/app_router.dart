import 'package:go_router/go_router.dart';

import '../screens/feedback_screen.dart';
import '../screens/rating_screen.dart';

/// Kiosk routes — `/feedback` is the entry point (§10.6, §10.7).
///
/// A factory keeps route state fresh per app instance (tests must not
/// inherit a leaked `/rating` location from the previous test).
GoRouter createAppRouter({String initialLocation = '/feedback'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/feedback',
      builder: (context, state) => const FeedbackScreen(),
    ),
    GoRoute(path: '/rating', builder: (context, state) => const RatingScreen()),
  ],
);

/// Production router.
final appRouter = createAppRouter();
