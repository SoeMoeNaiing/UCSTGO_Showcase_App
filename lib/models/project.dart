/// A showcase project visitors can rate — PROJECT_PROCESS.md §10.7, §6.1.
///
/// Pure domain entity: no Flutter, no assets, no Supabase. [id] is the
/// `project_id` written into a `ratings` row, so it must stay stable even
/// when the visible title changes.
final class Project {
  const Project({
    required this.id,
    required this.title,
    required this.blurb,
    this.imageAsset,
  });

  /// Stable identifier sent to the server as `project_id` (§6.1).
  final String id;

  /// Visible project name.
  final String title;

  /// One-line description shown on the polaroid.
  final String blurb;

  /// Optional bundled image; `null` means paint the sketch placeholder.
  final String? imageAsset;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Project &&
            other.id == id &&
            other.title == title &&
            other.blurb == blurb &&
            other.imageAsset == imageAsset;
  }

  @override
  int get hashCode => Object.hash(id, title, blurb, imageAsset);

  @override
  String toString() => 'Project($id: $title)';
}
