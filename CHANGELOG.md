# Changelog

## [0.0.1] - 2025-03-21

### Added
- Initial release of the network_speed plugin
- Support for both Android and iOS platforms
- Methods to retrieve current network type (mobile, WiFi, unknown)
- Methods to get download and upload speeds in Mbps
- WiFi signal strength measurement
- Real-time monitoring with stream-based API
- Background thread processing to prevent UI freezing
- Download speed testing functionality
- Upload speed testing functionality
- Example application with tabbed interface
- History tracking for network measurements
- Proper error handling and user feedback

### Technical Implementation
- Android: ConnectivityManager and NetworkCapabilities APIs
- Android: WifiManager for signal strength
- iOS: URLSessionDataDelegate for speed measurements
- iOS: SCNetworkReachabilityFlags for network type detection
- All operations run in background threads/queues

### Notes
- The plugin requires minimum Android SDK 21 and iOS 12.0
- Permission requirements added to documentation