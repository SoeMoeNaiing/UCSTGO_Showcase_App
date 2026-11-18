import '../../domain/entities/feedback.dart';

/// Transport outcome of one upload attempt — PROJECT_PROCESS.md §6.6.
///
/// The repository and sync engine speak this vocabulary, not HTTP codes:
/// mapping status codes to outcomes happens once, in the concrete remote
/// datasource (Iteration 15 / Iteration 38).
enum RemoteOutcome {
  /// `200` or replay `409` — the row is safely on the server.
  success,

  /// `429` — server rate limit; terminal, never retried (§6.8).
  rejected,

  /// `400` — malformed payload; a client bug, terminal.
  invalid,

  /// `5xx` — server-side failure; retry with backoff.
  serverError,

  /// Transport exception or timeout; retry with backoff.
  networkFailure,
}

/// Remote upload seam — implemented for real in Phase 6.
///
/// Contract: implementations **never throw**. Every transport failure is
/// mapped to [RemoteOutcome.networkFailure] so the UI and queue can trust
/// the local-first promise (§6.4).
abstract interface class FeedbackRemoteDataSource {
  /// Attempts one upload of [feedback] to the backend.
  Future<RemoteOutcome> submit(Feedback feedback);
}

/// The offline-phase remote: Phases 1–5 have no backend, so every attempt
/// is a network failure and the durable row stays `pending` — by design.
class UnavailableFeedbackRemoteDataSource implements FeedbackRemoteDataSource {
  const UnavailableFeedbackRemoteDataSource();

  @override
  Future<RemoteOutcome> submit(Feedback feedback) async =>
      RemoteOutcome.networkFailure;
}
