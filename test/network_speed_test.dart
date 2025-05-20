import 'package:flutter_test/flutter_test.dart';
import 'package:network_speed/network_speed.dart';
import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NetworkSpeed Tests', () {
    const MethodChannel channel = MethodChannel('network_speed');
    final List<MethodCall> log = <MethodCall>[];
    double mockSpeed = 50.0;
    String? mockTestFileUrl = 'http://example.com/test.file';

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'runDownloadSpeedTest') {
          return mockSpeed;
        }
        return null;
      });
      log.clear();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });

    test('runDownloadSpeedTest calls invokeMethod once and returns correct speed', () async {
      final double speed = await NetworkSpeed.runDownloadSpeedTest();

      expect(log, <Matcher>[
        isMethodCall('runDownloadSpeedTest', arguments: {'testFileUrl': null})
      ]);
      expect(speed, mockSpeed);
    });

    test('runDownloadSpeedTest with custom URL calls invokeMethod once and returns correct speed', () async {
      final double speed = await NetworkSpeed.runDownloadSpeedTest(testFileUrl: mockTestFileUrl);

      expect(log, <Matcher>[
        isMethodCall('runDownloadSpeedTest', arguments: {'testFileUrl': mockTestFileUrl})
      ]);
      expect(speed, mockSpeed);
    });
  });
}
