import 'dart:async';
import 'package:flutter/material.dart';
import 'package:network_speed/network_speed.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Speed Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const NetworkSpeedScreen(),
    );
  }
}

class NetworkSpeedScreen extends StatefulWidget {
  const NetworkSpeedScreen({super.key});

  @override
  _NetworkSpeedScreenState createState() => _NetworkSpeedScreenState();
}

class _NetworkSpeedScreenState extends State<NetworkSpeedScreen>
    with SingleTickerProviderStateMixin {
  // Network speed information
  Map<String, dynamic> _networkInfo = {
    'networkType': 'unknown',
    'downloadSpeed': 0.0,
    'uploadSpeed': 0.0,
    'signalStrength': -1,
  };

  // Speed test results
  double _downloadTestSpeed = 0.0;
  double _uploadTestSpeed = 0.0;

  // Loading states
  bool _isTestingDownload = false;
  bool _isTestingUpload = false;
  bool _isLoading = true;

  // Stream management
  Stream<Map<String, dynamic>>? _networkSpeedStream;
  StreamSubscription<Map<String, dynamic>>? _streamSubscription;
  bool _isStreamActive = false;

  // Tab controller
  late TabController _tabController;

  // History data
  final List<Map<String, dynamic>> _speedHistory = [];
  final int _maxHistoryItems = 20;
  Timer? _autoRefreshTimer;
  bool _autoRefresh = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeNetworkSpeed();
  }

  @override
  void dispose() {
    _stopStreaming();
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNetworkSpeed() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final networkInfo = await NetworkSpeed.getCurrentNetworkSpeed();
      setState(() {
        _networkInfo = networkInfo;
        _isLoading = false;

        // Add initial data to history
        _addToHistory(networkInfo);
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error initializing network speed: $e');
      _showErrorSnackBar('Failed to initialize network speed');
    }
  }

  void _addToHistory(Map<String, dynamic> data) {
    setState(() {
      // Add timestamp to the data
      final dataWithTimestamp = Map<String, dynamic>.from(data);
      dataWithTimestamp['timestamp'] = DateTime.now();

      _speedHistory.insert(0, dataWithTimestamp);

      // Limit history size
      if (_speedHistory.length > _maxHistoryItems) {
        _speedHistory.removeLast();
      }
    });
  }

  Future<void> _refreshNetworkSpeed() async {
    try {
      final networkInfo = await NetworkSpeed.getCurrentNetworkSpeed();
      setState(() {
        _networkInfo = networkInfo;

        // Add to history
        _addToHistory(networkInfo);
      });
    } catch (e) {
      print('Error refreshing network speed: $e');
      _showErrorSnackBar('Failed to refresh network speed');
    }
  }

  void _toggleAutoRefresh() {
    setState(() {
      _autoRefresh = !_autoRefresh;
    });

    if (_autoRefresh) {
      // Start auto-refresh timer (every 5 seconds)
      _autoRefreshTimer = Timer.periodic(Duration(seconds: 5), (timer) {
        _refreshNetworkSpeed();
      });
    } else {
      // Cancel timer
      _autoRefreshTimer?.cancel();
    }
  }

  Future<void> _runDownloadSpeedTest() async {
    setState(() {
      _isTestingDownload = true;
      _downloadTestSpeed = 0.0;
    });

    try {
      final speed = await NetworkSpeed.runDownloadSpeedTest();
      setState(() {
        _downloadTestSpeed = speed;
      });
      _showInfoSnackBar('Download speed test completed');
    } catch (e) {
      print('Error during download speed test: $e');
      _showErrorSnackBar('Download speed test failed');
    } finally {
      setState(() {
        _isTestingDownload = false;
      });
    }
  }

  Future<void> _runUploadSpeedTest() async {
    setState(() {
      _isTestingUpload = true;
      _uploadTestSpeed = 0.0;
    });

    try {
      final speed = await NetworkSpeed.runUploadSpeedTest();
      setState(() {
        _uploadTestSpeed = speed;
      });
      _showInfoSnackBar('Upload speed test completed');
    } catch (e) {
      print('Error during upload speed test: $e');
      _showErrorSnackBar('Upload speed test failed');
    } finally {
      setState(() {
        _isTestingUpload = false;
      });
    }
  }

  void _startStreaming() {
    // Stop any existing stream first
    _stopStreaming();

    setState(() {
      _isStreamActive = true;
      _networkSpeedStream = NetworkSpeed.getNetworkSpeedStream(interval: 1000);

      // Subscribe to the stream
      _streamSubscription = _networkSpeedStream?.listen((data) {
        setState(() {
          _networkInfo = data;

          // Add to history at a reduced rate (every 3 seconds)
          if (_speedHistory.isEmpty ||
              DateTime.now()
                      .difference(_speedHistory[0]['timestamp'])
                      .inSeconds >=
                  3) {
            _addToHistory(data);
          }
        });
      }, onError: (error) {
        print('Stream error: $error');
        _showErrorSnackBar('Real-time monitoring error');
        _stopStreaming();
      });
    });
  }

  void _stopStreaming() {
    _streamSubscription?.cancel();
    setState(() {
      _isStreamActive = false;
      _networkSpeedStream = null;
      _streamSubscription = null;
    });
  }

  void _toggleRealTimeMonitoring() {
    if (_isStreamActive) {
      _stopStreaming();
    } else {
      _startStreaming();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _getNetworkTypeIcon(String networkType) {
    switch (networkType) {
      case 'wifi':
        return '📶';
      case 'mobile':
        return '📱';
      default:
        return '❓';
    }
  }

  String _getSignalStrengthText(int strength) {
    switch (strength) {
      case 4:
        return 'Excellent';
      case 3:
        return 'Good';
      case 2:
        return 'Fair';
      case 1:
        return 'Poor';
      case 0:
        return 'No Signal';
      default:
        return 'N/A';
    }
  }

  Color _getSpeedColor(double speed) {
    if (speed <= 0) return Colors.grey;
    if (speed < 1) return Colors.red;
    if (speed < 5) return Colors.orange;
    if (speed < 20) return Colors.yellow.shade800;
    if (speed < 50) return Colors.green;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Speed Tester'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.speed), text: 'Current'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.assessment), text: 'Test'),
          ],
        ),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: Icon(_autoRefresh ? Icons.pause : Icons.refresh),
              tooltip: _autoRefresh ? 'Stop auto refresh' : 'Auto refresh',
              onPressed: _toggleAutoRefresh,
            ),
          if (_tabController.index == 0)
            IconButton(
              icon: Icon(_isStreamActive ? Icons.stop : Icons.play_arrow),
              tooltip:
                  _isStreamActive ? 'Stop monitoring' : 'Real-time monitoring',
              onPressed: _toggleRealTimeMonitoring,
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCurrentSpeedTab(),
          _buildHistoryTab(),
          _buildSpeedTestTab(),
        ],
      ),
    );
  }

  Widget _buildCurrentSpeedTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _refreshNetworkSpeed,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isStreamActive)
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              'Real-time monitoring active. Data updates every second.',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Network Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Divider(),
                          const SizedBox(height: 8.0),
                          _buildNetworkInfoRow(
                            'Network Type',
                            '${_getNetworkTypeIcon(_networkInfo['networkType'])} ${_networkInfo['networkType']}',
                            icon: Icons.network_cell,
                          ),
                          const SizedBox(height: 16.0),
                          _buildSpeedMeter(
                            'Download Speed',
                            _networkInfo['downloadSpeed'],
                            'Mbps',
                            Icons.download,
                          ),
                          const SizedBox(height: 24.0),
                          _buildSpeedMeter(
                            'Upload Speed',
                            _networkInfo['uploadSpeed'],
                            'Mbps',
                            Icons.upload,
                          ),
                          if (_networkInfo['networkType'] == 'wifi')
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 24.0),
                                _buildSignalStrength(
                                  'WiFi Signal',
                                  _networkInfo['signalStrength'],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  if (!_isStreamActive && !_autoRefresh)
                    Center(
                      child: Text(
                        'Pull down to refresh or tap the refresh button',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ),
          );
  }

  Widget _buildHistoryTab() {
    return _speedHistory.isEmpty
        ? Center(
            child: Text(
              'No history data available yet.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          )
        : ListView.builder(
            itemCount: _speedHistory.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              final item = _speedHistory[index];
              final time = item['timestamp'] as DateTime;
              final formattedTime =
                  '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

              return Card(
                margin:
                    const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getSpeedColor(item['downloadSpeed']),
                    child: Text(
                      _getNetworkTypeIcon(item['networkType']),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text('$formattedTime - ${item['networkType']}'),
                  subtitle: Text(
                    'Download: ${item['downloadSpeed'].toStringAsFixed(2)} Mbps\n'
                    'Upload: ${item['uploadSpeed'].toStringAsFixed(2)} Mbps',
                  ),
                  isThreeLine: true,
                  trailing: item['networkType'] == 'wifi' &&
                          item['signalStrength'] != -1
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            5,
                            (i) => Icon(
                              Icons.signal_cellular_alt,
                              size: 12,
                              color: i <= item['signalStrength']
                                  ? Colors.green
                                  : Colors.grey.shade400,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            },
          );
  }

  Widget _buildSpeedTestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Download Speed Test',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Tests your network\'s download capability by downloading a sample file.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16.0),
                  Center(
                    child: _buildSpeedTestResult(
                      _downloadTestSpeed,
                      _isTestingDownload,
                      Icons.download,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isTestingDownload ? null : _runDownloadSpeedTest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      child: _isTestingDownload
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Testing...'),
                              ],
                            )
                          : const Text('Start Download Test'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upload Speed Test',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Tests your network\'s upload capability by uploading a sample file.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16.0),
                  Center(
                    child: _buildSpeedTestResult(
                      _uploadTestSpeed,
                      _isTestingUpload,
                      Icons.upload,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isTestingUpload ? null : _runUploadSpeedTest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                      ),
                      child: _isTestingUpload
                          ? const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Testing...'),
                              ],
                            )
                          : const Text('Start Upload Test'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          Text(
            'Note: Speed tests use external test servers. Results may vary based on your location and server load.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkInfoRow(String label, String value, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildSpeedMeter(
      String label, double value, String unit, IconData icon) {
    final color = _getSpeedColor(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: value <= 0 ? 0 : (value > 100 ? 1 : value / 100),
                color: color,
                backgroundColor: Colors.grey.shade200,
                minHeight: 8,
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 70,
              child: Text(
                '${value.toStringAsFixed(1)} $unit',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignalStrength(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.network_wifi, size: 18),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Row(
                children: List.generate(
                  5,
                  (index) => Expanded(
                    child: Container(
                      height: 20,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= value
                            ? index >= 3
                                ? Colors.green
                                : index >= 1
                                    ? Colors.orange
                                    : Colors.red
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 70,
              child: Text(
                _getSignalStrengthText(value),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: value >= 3
                          ? Colors.green
                          : value >= 1
                              ? Colors.orange
                              : Colors.red,
                    ),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeedTestResult(double speed, bool isLoading, IconData icon) {
    if (isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final color = _getSpeedColor(speed);
    final speedText = speed <= 0 ? '--' : speed.toStringAsFixed(1);

    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: color,
          width: 8,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            speedText,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            'Mbps',
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
