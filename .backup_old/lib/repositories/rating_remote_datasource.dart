import 'package:ucstgo_showcase_flutter_app/models/remote_outcome.dart';

import './rating_model.dart';

/// Upload seam for one rating — implemented for real in Phase 6.
///
/// Takes the exact wire DTO so the only upload path is the §6.1 payload.
/// Contract: never throw; every transport failure maps to
/// [RemoteOutcome.networkFailure].
abstract interface class RatingRemoteDataSource {
  Future<RemoteOutcome> submit(RatingModel payload);
}

/// Offline-phase remote: no backend exists, so the row stays `pending`.
class UnavailableRatingRemoteDataSource implements RatingRemoteDataSource {
  const UnavailableRatingRemoteDataSource();

  @override
  Future<RemoteOutcome> submit(RatingModel payload) async =>
      RemoteOutcome.networkFailure;
}
