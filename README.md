# 🚀 Network Speed

![Banner](https://img.shields.io/badge/Network%20Speed-Flutter%20Plugin-blue?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=flat-square)
![Version](https://img.shields.io/badge/Version-0.0.1-green?style=flat-square)
[![Pub](https://img.shields.io/badge/Pub-Coming%20Soon-orange?style=flat-square)](https://pub.dev/)

A high-performance Flutter plugin that enables real-time network speed monitoring for both Android and iOS platforms. Check internet connection speed with precision and optimize your app's network-dependent features! ⚡

## ✨ Features

- 📱 **Cross-Platform**: Works seamlessly on both Android and iOS
- 🔄 **Real-time Monitoring**: Get continuous updates on network speed
- 🌐 **Network Type Detection**: Identify WiFi, mobile data, or no connection
- ⬇️ **Download Speed**: Accurate download speed measurements in Mbps
- ⬆️ **Upload Speed**: Precise upload speed measurements in Mbps
- 📊 **Signal Strength**: WiFi signal strength indicator (1-5)
- 🧵 **Background Processing**: All operations run on background threads to prevent UI freezing
- 🧪 **Speed Tests**: Run dedicated download and upload speed tests
- ⏱️ **Streaming API**: Subscribe to real-time network speed updates
- 🔌 **Easy Integration**: Simple API to quickly add network monitoring to your app

## 📋 Requirements

- Flutter: >=3.3.0
- Dart: >=2.18.0
- Android: minSdkVersion 21
- iOS: iOS 12.0 or later

## 📲 Installation

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  network_speed: any
```

Then run:

```bash
flutter pub get
```

## 🔧 Setup

### Android Setup

No additional setup is required for Android! The plugin automatically adds the necessary permissions to your AndroidManifest.xml:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

### iOS Setup

For iOS, add the following to your `Info.plist` file:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app needs to access your network to measure internet speed.</string>
```

## 🧩 Usage

### Import the package

```dart
import 'package:network_speed/network_speed.dart';
```

### Get current network type

```dart
NetworkType networkType = await NetworkSpeed.getCurrentNetworkType();

switch (networkType) {
  case NetworkType.mobile:
    print('📱 Connected to mobile data');
    break;
  case NetworkType.wifi:
    print('📶 Connected to WiFi');
    break;
  case NetworkType.unknown:
    print('❓ Connection type unknown or offline');
    break;
}
```

### Get current download and upload speeds

```dart
// Get instant download speed
double downloadSpeed = await NetworkSpeed.getDownloadSpeed();
print('⬇️ Download speed: $downloadSpeed Mbps');

// Get instant upload speed
double uploadSpeed = await NetworkSpeed.getUploadSpeed();
print('⬆️ Upload speed: $uploadSpeed Mbps');
```

### Get all network information at once

```dart
Map<String, dynamic> networkInfo = await NetworkSpeed.getCurrentNetworkSpeed();

print('🌐 Network type: ${networkInfo['networkType']}');
print('⬇️ Download speed: ${networkInfo['downloadSpeed']} Mbps');
print('⬆️ Upload speed: ${networkInfo['uploadSpeed']} Mbps');
print('📶 Signal strength: ${networkInfo['signalStrength']}');
```

### Real-time monitoring with streams

```dart
// Start real-time monitoring with updates every second
StreamSubscription<Map<String, dynamic>> subscription = 
    NetworkSpeed.getNetworkSpeedStream(interval: 1000).listen((networkInfo) {
  print('⬇️ Download: ${networkInfo['downloadSpeed']} Mbps | ⬆️ Upload: ${networkInfo['uploadSpeed']} Mbps');
});

// Don't forget to cancel the subscription when no longer needed
subscription.cancel();
```

### Run speed tests

```dart
// Show loading indicator
showDialog(context: context, builder: (_) => LoadingDialog());

// Run download speed test
double downloadTestResult = await NetworkSpeed.runDownloadSpeedTest();
print('🔍 Download test result: $downloadTestResult Mbps');

// Run upload speed test
double uploadTestResult = await NetworkSpeed.runUploadSpeedTest();
print('🔍 Upload test result: $uploadTestResult Mbps');

// Hide loading indicator
Navigator.of(context).pop();

// You can also specify a custom URL for testing
double customDownloadTest = await NetworkSpeed.runDownloadSpeedTest(
  testFileUrl: 'https://your-test-file-url.com/file.bin'
);
```

## 📱 Example App Screenshots

<table>
  <tr>
    <td align="center"><img src="https://via.placeholder.com/250x500?text=Current+Speed" alt="Current Speed"/></td>
    <td align="center"><img src="https://via.placeholder.com/250x500?text=History" alt="History"/></td>
    <td align="center"><img src="https://via.placeholder.com/250x500?text=Speed+Test" alt="Speed Test"/></td>
  </tr>
  <tr>
    <td align="center">Current Speed</td>
    <td align="center">History</td>
    <td align="center">Speed Test</td>
  </tr>
</table>

## 🧠 How It Works

### Android Implementation
- Uses Android's `ConnectivityManager` and `NetworkCapabilities` APIs for real-time network speed detection
- Implements `WifiManager` for WiFi signal strength
- All operations run on background threads to prevent UI freezing

### iOS Implementation
- Implements `URLSessionDataDelegate` for accurate download and upload speed measurements
- Uses `SCNetworkReachabilityFlags` for network type detection
- All operations run on background queues to prevent UI freezing

## 📊 Speed Interpretation

Here's a quick guide to interpret the speed results:

| Speed (Mbps) | Quality | Suitable For |
|--------------|---------|--------------|
| < 1 | 🔴 Poor | Basic web browsing |
| 1-5 | 🟠 Fair | SD video streaming |
| 5-20 | 🟡 Good | HD video streaming |
| 20-50 | 🟢 Very Good | 4K streaming |
| 50+ | 🔵 Excellent | Multiple 4K streams |

## 📝 Notes

- Speed tests require an active internet connection
- Results may vary based on server load and network conditions
- For most accurate results, run multiple tests and average the results
- The plugin uses minimal resources to measure network speed
- All operations run on background threads to prevent UI freezing

## 🤝 Contributing

Contributions are welcome! Feel free to submit issues or pull requests if you have any improvements or bug fixes.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ✨ Author

Made with ❤️ by [Your Name](https://github.com/yourusername)

## 🙏 Acknowledgments

- Flutter Team for the amazing framework
- All contributors who helped improve this plugin