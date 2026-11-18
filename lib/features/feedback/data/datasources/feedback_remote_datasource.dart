import '../models/feedback_model.dart';

/// Transport outcome of one upload attempt — PROJECT_PROCESS.md §6.6.
///
/// The repository and sync engine speak this vocabulary, not HTTP codes:
/// mapping status codes to outcomes happens once, in [mapHttpStatus], so
/// Phase 6's concrete datasource and the offline build behave identically.
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
///
/// | Status | Outcome | Why |
/// |---|---|---|
/// | `2xx`, `409` | [RemoteOutcome.success] | inserted, or idempotent replay |
/// | `429` | [RemoteOutcome.rejected] | visitor over the rate limit; terminal |
/// | `400` | [RemoteOutcome.invalid] | malformed payload; terminal |
/// | other `4xx` | [RemoteOutcome.invalid] | bad key/URL/route — retrying cannot fix it |
/// | `5xx` | [RemoteOutcome.serverError] | server fault; retry |
/// | anything else | [RemoteOutcome.networkFailure] | proxy/portal interference; retry |
///
/// Only `200` is contractual; accepting every `2xx` keeps a proxy that
/// answers `204` from stranding a successful row in the queue.
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

/// Remote upload seam — implemented for real in Phase 6.
///
/// Takes the exact wire DTO, not the domain entity, so the only upload path
/// is the §6.2 payload. Contract: implementations **never throw**. Every
/// transport failure is mapped to [RemoteOutcome.networkFailure] so the UI
/// and queue can trust the local-first promise (§6.4).
abstract interface class FeedbackRemoteDataSource {
  /// Attempts one upload of [payload] to the backend.
  Future<RemoteOutcome> submit(FeedbackModel payload);
}

/// The offline-phase remote: Phases 1–5 have no backend, so every attempt
/// is a network failure and the durable row stays `pending` — by design.
class UnavailableFeedbackRemoteDataSource implements FeedbackRemoteDataSource {
  const UnavailableFeedbackRemoteDataSource();

  @override
  Future<RemoteOutcome> submit(FeedbackModel payload) async =>
      RemoteOutcome.networkFailure;
}
