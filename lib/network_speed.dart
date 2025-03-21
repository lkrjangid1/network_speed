import 'dart:async';
import 'package:flutter/services.dart';

/// NetworkType enum to represent different network types
enum NetworkType { mobile, wifi, unknown }

/// NetworkSpeed class that provides methods to check network speed
class NetworkSpeed {
  static const MethodChannel _channel = MethodChannel('network_speed');

  /// Get the current network type (mobile, wifi, or unknown)
  static Future<NetworkType> getCurrentNetworkType() async {
    final String networkType =
        await _channel.invokeMethod('getCurrentNetworkType');
    switch (networkType) {
      case 'mobile':
        return NetworkType.mobile;
      case 'wifi':
        return NetworkType.wifi;
      default:
        return NetworkType.unknown;
    }
  }

  /// Get download speed in Mbps
  static Future<double> getDownloadSpeed() async {
    final double speed = await _channel.invokeMethod('getDownloadSpeed');
    return speed;
  }

  /// Get upload speed in Mbps
  static Future<double> getUploadSpeed() async {
    final double speed = await _channel.invokeMethod('getUploadSpeed');
    return speed;
  }

  /// Get current network speed details
  /// Returns a Map containing network type, download speed, and upload speed
  static Future<Map<String, dynamic>> getCurrentNetworkSpeed() async {
    final Map<dynamic, dynamic> result =
        await _channel.invokeMethod('getCurrentNetworkSpeed');
    return {
      'networkType': result['networkType'],
      'downloadSpeed': result['downloadSpeed'],
      'uploadSpeed': result['uploadSpeed'],
      'signalStrength': result['signalStrength'],
    };
  }

  /// Stream that emits network speed updates continuously
  /// Interval parameter defines how often to check (in milliseconds)
  static Stream<Map<String, dynamic>> getNetworkSpeedStream(
      {int interval = 1000}) {
    return Stream.periodic(Duration(milliseconds: interval))
        .asyncMap((_) async {
      return await getCurrentNetworkSpeed();
    });
  }

  /// Run a speed test by downloading a test file
  /// Returns download speed in Mbps
  static Future<double> runDownloadSpeedTest({String? testFileUrl}) async {
    final Map<dynamic, dynamic> args = {'testFileUrl': testFileUrl};
    await _channel.invokeMethod('runDownloadSpeedTest', args);
    final double speed =
        await _channel.invokeMethod('runDownloadSpeedTest', args);
    return speed;
  }

  /// Run a speed test by uploading a test file
  /// Returns upload speed in Mbps
  static Future<double> runUploadSpeedTest({String? testFileUrl}) async {
    final Map<dynamic, dynamic> args = {'testFileUrl': testFileUrl};
    final double speed =
        await _channel.invokeMethod('runUploadSpeedTest', args);
    return speed;
  }
}
