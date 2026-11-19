import '../../domain/entities/project.dart';

/// Six placeholder showcase projects — no assets to load (I25).
///
/// Ids are deliberately stable: they become `project_id` in the ratings
/// table (§6.1). Supabase replaces this list with a real query in Phase 6;
/// the UI only ever depends on the [Project] entity.
const projectFixtures = <Project>[
  Project(
    id: 'campus-navigator',
    title: 'Campus Navigator',
    blurb: 'Find your way across UCSTGO in one tap.',
  ),
  Project(
    id: 'canteen-queue',
    title: 'Canteen Queue',
    blurb: 'See the wait before you walk over.',
  ),
  Project(
    id: 'scholarship-finder',
    title: 'Scholarship Finder',
    blurb: 'Opportunities matched to your profile.',
  ),
  Project(
    id: 'library-lens',
    title: 'Library Lens',
    blurb: 'Scan a shelf, find the right book.',
  ),
  Project(
    id: 'events-radar',
    title: 'Events Radar',
    blurb: 'What is happening on campus today?',
  ),
  Project(
    id: 'study-buddy',
    title: 'Study Buddy',
    blurb: 'Pair up with classmates who care.',
  ),
];
