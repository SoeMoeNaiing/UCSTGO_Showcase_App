import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ucstgo_showcase_flutter_app/services/connectivity_service.dart';

/// Fake physical link with a manually driven change stream.
class _FakeLink implements LinkStatusSource {
  _FakeLink({this.up = true});

  bool up;
  bool throwOnCheck = false;
  int checks = 0;

  final _changes = StreamController<bool>.broadcast();

  @override
  Future<bool> hasLink() async {
    checks++;
    if (throwOnCheck) {
      throw StateError('link plugin exploded');
    }
    return up;
  }

  @override
  Stream<bool> get onLinkChange => _changes.stream;

  void emit(bool value) {
    up = value;
    _changes.add(value);
  }

  Future<void> close() => _changes.close();
}

/// Fake reachability probe, optionally gated to create in-flight windows.
class _FakeProbe implements ReachabilityProbe {
  bool result = true;
  Object? error;
  Completer<void>? gate;
  int calls = 0;
  bool disposed = false;

  @override
  Future<bool> probe() async {
    calls++;
    final blocker = gate;
    if (blocker != null) {
      await blocker.future;
    }
    final failure = error;
    if (failure != null) {
      throw failure;
    }
    return result;
  }

  @override
  void dispose() => disposed = true;
}

/// Iteration 14 — ConnectivityService (§6.7).
///
/// Proves the trusted-online contract without touching the network:
/// link-down short-circuits, captive portals read as offline, rising edges
/// re-probe, and concurrent checks coalesce.
void main() {
  late _FakeLink link;
  late _FakeProbe probe;
  late ConnectivityService service;

  void build({bool up = true}) {
    link = _FakeLink(up: up);
    probe = _FakeProbe();
    service = ConnectivityService(link: link, probe: probe);
    addTearDown(() async {
      await service.dispose();
      await link.close();
    });
  }

  group('ConnectivityService (§6.7)', () {
    test('link down at start: offline and the probe is never called', () async {
      build(up: false);

      final online = await service.start();

      expect(online, isFalse);
      expect(service.isOnline, isFalse);
      expect(probe.calls, 0, reason: 'no link means the 5s probe is pointless');
      expect(link.checks, 1);
    });

    test('link up + reachable backend: online', () async {
      build();

      final online = await service.start();

      expect(online, isTrue);
      expect(service.isOnline, isTrue);
      expect(probe.calls, 1);
    });

    test('link up + unreachable backend: offline (captive portal)', () async {
      build();
      probe.result = false;

      final online = await service.start();

      expect(online, isFalse, reason: 'Wi-Fi alone is not internet access');
      expect(service.isOnline, isFalse);
      expect(probe.calls, 1);
    });

    test('a throwing probe is treated as offline, never propagated', () async {
      build();
      probe.error = Exception('connection refused');

      expect(await service.start(), isFalse);
      expect(service.isOnline, isFalse);
    });

    test('a throwing link check is treated as offline', () async {
      build();
      link.throwOnCheck = true;

      expect(await service.start(), isFalse);
      expect(service.isOnline, isFalse);
      expect(probe.calls, 0);
    });

    test('a link drop goes offline immediately without probing', () async {
      build();
      await service.start();
      expect(service.isOnline, isTrue);
      final emissions = <bool>[];
      service.online.listen(emissions.add);

      link.emit(false);
      await pumpEventQueue();

      expect(service.isOnline, isFalse);
      expect(probe.calls, 1, reason: 'the probe count must not grow');
      expect(emissions, [false]);
    });

    test('link recovery re-probes and emits the rising edge', () async {
      build(up: false);
      await service.start();
      expect(service.isOnline, isFalse);
      final emissions = <bool>[];
      service.online.listen(emissions.add);

      link.emit(true);
      await pumpEventQueue();

      expect(probe.calls, 1);
      expect(service.isOnline, isTrue);
      expect(emissions, [true]);
    });

    test('the online stream emits only on changes', () async {
      build();
      await service.start(); // becomes online before anyone listens
      final emissions = <bool>[];
      service.online.listen(emissions.add);

      await service.checkNow();
      await pumpEventQueue();
      expect(emissions, isEmpty, reason: 'still online, no new edge');

      link.emit(false);
      await pumpEventQueue();
      expect(emissions, [false]);

      link.emit(false);
      await pumpEventQueue();
      expect(emissions, [false], reason: 'repeated offline is not a change');
    });

    test('concurrent checkNow calls share one probe', () async {
      build();
      probe.gate = Completer<void>();

      final first = service.checkNow();
      final second = service.checkNow();
      await pumpEventQueue();

      expect(identical(first, second), isTrue);
      expect(probe.calls, 1);

      probe.gate!.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(probe.calls, 1);
    });

    test('a link drop during an in-flight probe keeps it offline', () async {
      build();
      probe.gate = Completer<void>();

      final starting = service.start();
      await pumpEventQueue();
      expect(probe.calls, 1);

      link.emit(false);
      probe.gate!.complete();

      expect(await starting, isFalse);
      expect(service.isOnline, isFalse);
    });

    test('dispose cancels the subscription, closes the stream, frees probe',
        () async {
      build();
      await service.start();

      await service.dispose();
      expect(probe.disposed, isTrue);
      await expectLater(service.online, emitsDone);

      // A late link event after disposal must be harmless.
      link.emit(true);
      await pumpEventQueue();
      expect(service.isOnline, isTrue);
    });

    test('start is idempotent for the link subscription', () async {
      build();

      await service.start();
      await service.start();

      expect(link.checks, 2, reason: 'two explicit starts, two checks');
      expect(probe.calls, 2);
      expect(service.isOnline, isTrue);

      link.emit(true);
      await pumpEventQueue();
      expect(probe.calls, 3, reason: 'one link event, one probe — not two');
    });
  });

  group('HttpReachabilityProbe (§6.7)', () {
    test('a blank base URL is link-only and never hits the network', () async {
      final probe = HttpReachabilityProbe(baseUrl: '   ');
      addTearDown(probe.dispose);

      expect(await probe.probe(), isTrue);
    });

    test('an invalid base URL reads as unreachable', () async {
      final probe = HttpReachabilityProbe(baseUrl: 'http://[::1');
      addTearDown(probe.dispose);

      expect(await probe.probe(), isFalse);
    });
  });

  group('ConnectivityPlusLinkSource (§6.7)', () {
    test('maps connectivity results to a boolean link state', () {
      expect(
        ConnectivityPlusLinkSource.hasUsableLink([ConnectivityResult.none]),
        isFalse,
      );
      expect(
        ConnectivityPlusLinkSource.hasUsableLink([ConnectivityResult.wifi]),
        isTrue,
      );
      expect(
        ConnectivityPlusLinkSource.hasUsableLink([ConnectivityResult.ethernet]),
        isTrue,
      );
      expect(
        ConnectivityPlusLinkSource.hasUsableLink([ConnectivityResult.mobile]),
        isTrue,
      );
      expect(
        ConnectivityPlusLinkSource.hasUsableLink([ConnectivityResult.bluetooth]),
        isTrue,
      );
    });
  });
}
