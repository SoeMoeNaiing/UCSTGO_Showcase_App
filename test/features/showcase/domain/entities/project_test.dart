import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/repositories/project_fixtures.dart';
import 'package:ucstgo_showcase_flutter_app/models/project.dart';

/// Iteration 25 — Project entity + fixture invariants (§10.7, §6.1).
void main() {
  group('Project (§10.7)', () {
    test('value equality is based on all four fields', () {
      const a = Project(id: 'one', title: 'Title', blurb: 'Blurb');
      const same = Project(id: 'one', title: 'Title', blurb: 'Blurb');
      const different = Project(id: 'two', title: 'Title', blurb: 'Blurb');
      const withAsset = Project(
        id: 'one',
        title: 'Title',
        blurb: 'Blurb',
        imageAsset: 'assets/x.png',
      );

      expect(a, same);
      expect(a.hashCode, same.hashCode);
      expect(a, isNot(different));
      expect(a, isNot(withAsset));
      expect(a.imageAsset, isNull);
    });

    test('fixtures are six distinct, complete placeholder projects', () {
      expect(projectFixtures, hasLength(6));
      expect(
        projectFixtures.map((project) => project.id).toSet(),
        hasLength(6),
        reason: 'project_id is the ratings foreign key (§6.1)',
      );
      for (final project in projectFixtures) {
        expect(project.id, isNotEmpty);
        expect(project.title, isNotEmpty);
        expect(project.blurb, isNotEmpty);
        expect(project.imageAsset, isNull, reason: 'no assets to load yet');
      }
    });
  });
}
