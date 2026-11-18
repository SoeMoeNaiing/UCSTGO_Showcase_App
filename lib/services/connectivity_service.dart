import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Physical-link seam — "is a network interface attached?" (§6.7).
///
/// This deliberately says **nothing** about internet access: a Wi-Fi icon
/// can be lit while the kiosk sits behind a captive portal. Link state is
/// only the cheap first question; [ReachabilityProbe] asks the second.
abstract interface class LinkStatusSource {
  /// One-shot link check. Implementations never throw.
  Future<bool> hasLink();

  /// Emits `true`/`false` whenever the physical link changes.
  Stream<bool> get onLinkChange;
}

/// Production link source backed by `connectivity_plus`.
class ConnectivityPlusLinkSource implements LinkStatusSource {
  ConnectivityPlusLinkSource({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Only `none` means the link is down; any transport counts as up.
  static bool hasUsableLink(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);

  @override
  Future<bool> hasLink() async {
    try {
      return hasUsableLink(await _connectivity.checkConnectivity());
    } catch (_) {
      // A plugin failure is reported as "no link" — sync stays paused.
      return false;
    }
  }

  @override
  Stream<bool> get onLinkChange =>
      _connectivity.onConnectivityChanged.map(hasUsableLink);
}

/// Reachability seam — can we actually reach the backend? (§6.7).
abstract interface class ReachabilityProbe {
  /// `true` when the backend answered. Implementations never throw.
  Future<bool> probe();

  /// Releases any underlying resources (e.g. the HTTP client).
  void dispose();
}

/// Production probe: `HEAD` to the configured backend base URL.
///
/// **Captive-portal note:** a completed TLS response from the real host is
/// the proof we need. A portal that hijacks the connection either fails TLS
/// or returns a non-2xx/3xx page; either way the kiosk stays offline and
/// submissions keep queuing locally instead of vanishing.
///
/// With no `SUPABASE_URL` configured (Phases 1–5) the probe is link-only:
/// there is nothing to upload to, so a live link is the best answer.
class HttpReachabilityProbe implements ReachabilityProbe {
  HttpReachabilityProbe({
    required String baseUrl,
    this.timeout = const Duration(seconds: 5),
    HttpClient? client,
  })  : baseUrl = baseUrl.trim(),
        _client = client ?? HttpClient();

  final String baseUrl;
  final Duration timeout;
  final HttpClient _client;

  @override
  Future<bool> probe() async {
    if (baseUrl.isEmpty) {
      return true;
    }

    try {
      final request = await _client.headUrl(Uri.parse(baseUrl)).timeout(timeout);
      // A portal redirect is not the backend talking — treat it as failure.
      request.followRedirects = false;
      final response = await request.close().timeout(timeout);
      await response.drain<void>().timeout(timeout);
      // Any non-5xx answer — including 401 from an unauthenticated HEAD —
      // proves the host is alive and reachable.
      return response.statusCode < 500;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() => _client.close(force: true);
}

/// Combines link state and reachability into one trusted `online` signal.
///
/// Rules (§6.7):
/// - Link down → **offline immediately**, no probe (saves the 5s timeout).
/// - Link up → probe. Probe fails → offline, even though Wi-Fi says yes.
/// - Link change → probe again; a rising edge is what unblocks the queue.
/// - Concurrent [checkNow] calls share one in-flight check, so a burst of
///   triggers cannot stampede the network.
class ConnectivityService {
  ConnectivityService({
    required this.link,
    required this.probe,
  });

  final LinkStatusSource link;
  final ReachabilityProbe probe;

  final _onlineController = StreamController<bool>.broadcast();

  StreamSubscription<bool>? _linkSubscription;
  Future<bool>? _inFlight;
  bool _online = false;
  bool _linkUp = false;
  bool _disposed = false;

  /// Last known answer. Starts `false` until [start] or [checkNow] runs.
  bool get isOnline => _online;

  /// Emits only on **changes** (rising and falling edges), never replays.
  /// Pair it with [isOnline] for the current value.
  Stream<bool> get online => _onlineController.stream;

  /// Begins observing link changes and performs the first check.
  ///
  /// Idempotent: calling it twice keeps one subscription and coalesces the
  /// checks.
  Future<bool> start() {
    if (_disposed) {
      return Future.value(false);
    }
    _linkSubscription ??= link.onLinkChange.listen(_onLinkChange);
    return checkNow();
  }

  /// Runs one link + reachability check now.
  ///
  /// Concurrent callers share the same future, so the scheduler can fire
  /// several triggers at once without producing several probes.
  Future<bool> checkNow() {
    if (_disposed) {
      return Future.value(false);
    }
    return _inFlight ??= _check().whenComplete(() => _inFlight = null);
  }

  Future<bool> _check() async {
    final hasLink = await _safeHasLink();
    _linkUp = hasLink;
    if (!hasLink) {
      return _setOnline(false);
    }

    final reachable = await _safeProbe();
    // The link may have dropped while the probe was in flight; never
    // publish "online" from a stale probe.
    if (!_linkUp) {
      return _setOnline(false);
    }
    return _setOnline(reachable);
  }

  Future<bool> _safeHasLink() async {
    try {
      return await link.hasLink();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _safeProbe() async {
    try {
      return await probe.probe();
    } catch (_) {
      return false;
    }
  }

  void _onLinkChange(bool hasLink) {
    if (_disposed) {
      return;
    }
    _linkUp = hasLink;
    if (!hasLink) {
      _setOnline(false);
      return;
    }
    unawaited(checkNow());
  }

  bool _setOnline(bool value) {
    if (_online == value) {
      return value;
    }
    _online = value;
    if (!_disposed) {
      _onlineController.add(value);
    }
    return value;
  }

  /// Stops observing, closes the stream, and releases the probe.
  ///
  /// Ownership note: the service owns the [probe] but not the [link] source,
  /// so the link's stream is left for its creator.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _linkSubscription?.cancel();
    _linkSubscription = null;
    await _onlineController.close();
    probe.dispose();
  }
}
