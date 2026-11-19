import '../models/remote_outcome.dart';
export '../models/remote_outcome.dart';

import './feedback_model.dart';

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
