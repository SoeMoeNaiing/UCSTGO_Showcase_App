/// Transport outcome of one queue-upload attempt — §6.6.
///
/// Shared by feedback and ratings so the sync engine needs one vocabulary.
/// Mapping HTTP codes happens once, in [mapHttpStatus], so Phase 6's real
/// datasources and the offline build behave identically.
enum RemoteOutcome {
  /// `200`/`2xx` or replay `409` — the row is safely on the server.
  success,

  /// `429` — server rate limit; terminal, never retried (§6.8).
  rejected,

  /// `400` (and other terminal 4xx) — a client/config bug, terminal.
  invalid,

  /// `5xx` — server-side failure; retry with backoff.
  serverError,

  /// Transport exception, timeout, redirect, or unexpected status; retry
  /// with backoff.
  networkFailure,
}

/// Pure HTTP-status → queue-outcome table (§6.6).
RemoteOutcome mapHttpStatus(int statusCode) {
  if ((statusCode >= 200 && statusCode < 300) || statusCode == 409) {
    return RemoteOutcome.success;
  }
  if (statusCode == 429) {
    return RemoteOutcome.rejected;
  }
  if (statusCode == 400) {
    return RemoteOutcome.invalid;
  }
  if (statusCode >= 500 && statusCode < 600) {
    return RemoteOutcome.serverError;
  }
  if (statusCode >= 400 && statusCode < 500) {
    // 401 / 403 / 404 … are configuration mistakes, not transient faults.
    return RemoteOutcome.invalid;
  }
  return RemoteOutcome.networkFailure;
}
