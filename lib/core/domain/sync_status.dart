/// Queue lifecycle for a submission — PROJECT_PROCESS.md §6.6.
///
/// Every local queue row carries one of these values. [pending] is the
/// only non-terminal state: the SyncService retries it with exponential
/// backoff until it becomes [synced] (200/409), [rejected] (429 — rate
/// limited, do not retry) or [failedPermanent] (400 — a client bug).
enum SyncStatus {
  /// Durable locally; upload pending or retry scheduled via nextRetryAt.
  pending('pending'),

  /// Server accepted (200) or replay detected (409) — terminal, row
  /// leaves the queue (§6.6).
  synced('synced'),

  /// Rate limited (429) — terminal, never retried (§6.8).
  rejected('rejected'),

  /// Malformed payload (400) — terminal; signals a client bug.
  failedPermanent('failed_permanent');

  const SyncStatus(this.wireValue);

  /// Exact string stored in Drift and referenced by the schema (§6.6).
  final String wireValue;

  /// True once the sync engine must stop retrying this row.
  bool get isTerminal => this != pending;

  /// Serializes for Drift/Postgres storage.
  String toJson() => wireValue;

  /// Parses a stored/transmitted value; unknown values are data bugs.
  static SyncStatus fromJson(String value) {
    for (final status in values) {
      if (status.wireValue == value) {
        return status;
      }
    }
    throw FormatException('Unknown SyncStatus wire value: "$value"');
  }
}
