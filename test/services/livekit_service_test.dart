import 'package:flutter_test/flutter_test.dart';
import 'package:micraa_flutter/services/livekit_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

/// A fake wakelock platform that just records enable/disable calls, so the
/// wakelock lifecycle can be asserted without a real device/plugin.
class _FakeWakelockPlatform extends WakelockPlusPlatformInterface {
  bool _enabled = false;
  final List<bool> calls = [];

  @override
  Future<void> toggle({required bool enable}) async {
    calls.add(enable);
    _enabled = enable;
  }

  @override
  Future<bool> get enabled async => _enabled;
}

void main() {
  late _FakeWakelockPlatform fakeWakelock;

  setUp(() {
    fakeWakelock = _FakeWakelockPlatform();
    wakelockPlusPlatformInstance = fakeWakelock;
  });

  group('wakelock lifecycle (ticket-001)', () {
    test('disconnect() releases the wakelock even if never connected', () async {
      final service = LiveClassRoomService();

      await service.disconnect();

      expect(fakeWakelock.calls, contains(false));
      expect(await WakelockPlus.enabled, isFalse);
    });

    test('dispose() releases the wakelock (covers widget disposal)', () async {
      final service = LiveClassRoomService();

      service.dispose();
      // dispose() fires disconnect() without awaiting it; let the microtask run.
      await Future<void>.delayed(Duration.zero);

      expect(fakeWakelock.calls, contains(false));
    });

    test('a failed connection never enables the wakelock', () async {
      final service = LiveClassRoomService();

      // Nothing listens on this loopback port: connection is refused quickly,
      // exercising the same catch-block path as any other connection failure.
      await expectLater(
        service.connect('ws://127.0.0.1:1', 'invalid-token'),
        throwsA(anything),
      );

      expect(fakeWakelock.calls, isNot(contains(true)));
      expect(await WakelockPlus.enabled, isFalse);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });

  group('teacher-forced microphone mute (ticket-001)', () {
    test('forced mute overrides local mic state and cannot be toggled off locally', () async {
      final service = LiveClassRoomService();
      expect(service.isForceMuted, isFalse);

      service.applyForceMuteState(true);
      expect(service.isForceMuted, isTrue);
      expect(service.isMicEnabled, isFalse);

      // The student's own mic toggle is a no-op while force-muted: no LiveKit
      // room is even attached here, so any attempt to actually toggle would
      // throw - proving toggleMic() short-circuits before touching the room.
      await service.toggleMic();
      expect(service.isForceMuted, isTrue);
      expect(service.isMicEnabled, isFalse);
    });

    test('forced unmute clears the override', () async {
      final service = LiveClassRoomService();
      service.applyForceMuteState(true);

      service.applyForceMuteState(false);

      expect(service.isForceMuted, isFalse);
      expect(service.isMicEnabled, isTrue);
    });
  });
}
