import Flutter
import UIKit
import SystemConfiguration
import CoreTelephony
import Network

@available(iOS 12.0, *)
public class NetworkSpeedPlugin: NSObject, FlutterPlugin, URLSessionDataDelegate {
    private var downloadStartTime: CFAbsoluteTime = 0
    private var downloadedBytes: Int = 0
    private var downloadResult: FlutterResult?
    private var uploadResult: FlutterResult?
    private var uploadStartTime: CFAbsoluteTime = 0
    private var uploadedBytes: Int = 0
    private let operationQueue = OperationQueue()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "network_speed", binaryMessenger: registrar.messenger())
        let instance = NetworkSpeedPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCurrentNetworkType":
            operationQueue.addOperation {
                let networkType = self.getCurrentNetworkType()
                DispatchQueue.main.async {
                    result(networkType)
                }
            }
        case "getDownloadSpeed":
            operationQueue.addOperation {
                let speed = self.getEstimatedDownloadSpeed()
                DispatchQueue.main.async {
                    result(speed)
                }
            }
        case "getUploadSpeed":
            operationQueue.addOperation {
                let speed = self.getEstimatedUploadSpeed()
                DispatchQueue.main.async {
                    result(speed)
                }
            }
        case "getCurrentNetworkSpeed":
            operationQueue.addOperation {
                let networkInfo = self.getCurrentNetworkSpeed()
                DispatchQueue.main.async {
                    result(networkInfo)
                }
            }
        case "runDownloadSpeedTest":
            let args = call.arguments as? [String: Any]
            let testFileUrl = args?["testFileUrl"] as? String ?? "https://filesamples.com/samples/document/txt/sample3.txt"
            self.downloadResult = result
            self.runDownloadSpeedTest(fileUrl: testFileUrl)
        case "runUploadSpeedTest":
            let args = call.arguments as? [String: Any]
            let testFileUrl = args?["testFileUrl"] as? String ?? "https://httpbin.org/post"
            self.uploadResult = result
            self.runUploadSpeedTest(fileUrl: testFileUrl)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getCurrentNetworkType() -> String {
        let reachability = SCNetworkReachabilityCreateWithName(nil, "www.apple.com")
        var flags = SCNetworkReachabilityFlags()
        SCNetworkReachabilityGetFlags(reachability!, &flags)

        let isReachable = flags.contains(.reachable)
        let isWWAN = flags.contains(.isWWAN)

        if isReachable {
            if isWWAN {
                return "mobile"
            } else {
                return "wifi"
            }
        } else {
            return "unknown"
        }
    }

    private func getEstimatedDownloadSpeed() -> Double {
        if #available(iOS 13.0, *) {
            let monitor = NWPathMonitor()
            var downloadSpeed: Double = 0.0

            let semaphore = DispatchSemaphore(value: 0)

            monitor.pathUpdateHandler = { path in
                // Estimate speed based on interface type and performance
                if path.usesInterfaceType(.wifi) {
                    // WiFi typically has higher bandwidth
                    downloadSpeed = path.isExpensive ? 10.0 : 25.0
                } else if path.usesInterfaceType(.cellular) {
                    // Cellular connection with a moderate estimate
                    downloadSpeed = path.isExpensive ? 5.0 : 8.0
                } else if path.usesInterfaceType(.wiredEthernet) {
                    // Wired connections typically have good performance
                    downloadSpeed = 50.0
                } else {
                    // Unknown or other connection types
                    downloadSpeed = 1.0
                }

                // Adjust based on connection quality
                if !path.isConstrained && path.status == .satisfied {
                    downloadSpeed *= 1.5
                }

                semaphore.signal()
                monitor.cancel()
            }

            let queue = DispatchQueue(label: "NetworkMonitor")
            monitor.start(queue: queue)

            _ = semaphore.wait(timeout: .now() + 1.0)

            return downloadSpeed
        } else {
            // Fallback for older iOS versions
            return 5.0 // Provide a reasonable default
        }
    }

    private func getEstimatedUploadSpeed() -> Double {
        // For simplicity, return a similar value to download speed
        // In real-world scenarios, upload is typically slower than download
        return getEstimatedDownloadSpeed() * 0.5
    }

    private func getWifiSignalStrength() -> Int {
        // iOS doesn't provide a direct API for signal strength
        // This is a placeholder - in a real app you would need a more complex solution
        return -1
    }

    private func getCurrentNetworkSpeed() -> [String: Any] {
        let networkType = getCurrentNetworkType()
        let downloadSpeed = getEstimatedDownloadSpeed()
        let uploadSpeed = getEstimatedUploadSpeed()
        let signalStrength = networkType == "wifi" ? getWifiSignalStrength() : -1

        return [
            "networkType": networkType,
            "downloadSpeed": downloadSpeed,
            "uploadSpeed": uploadSpeed,
            "signalStrength": signalStrength
        ]
    }

    private func runDownloadSpeedTest(fileUrl: String) {
        guard let url = URL(string: fileUrl) else {
            downloadResult?(0.0)
            return
        }

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30

        var request = URLRequest(url: url)
        request.addValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)

        downloadedBytes = 0
        downloadStartTime = CFAbsoluteTimeGetCurrent()

        let task = session.dataTask(with: request)
        task.resume()
    }

    private func runUploadSpeedTest(fileUrl: String) {
        guard let url = URL(string: fileUrl) else {
            uploadResult?(0.0)
            return
        }

        // Create a test data payload (1MB)
        let testData = Data(count: 1024 * 1024)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = testData
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")

        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)

        uploadedBytes = testData.count
        uploadStartTime = CFAbsoluteTimeGetCurrent()

        let task = session.dataTask(with: request) { _, _, error in
            let stopTime = CFAbsoluteTimeGetCurrent()
            let elapsedTime = max(stopTime - self.uploadStartTime, 0.001) // Avoid division by zero

            // Calculate speed in Mbps (bytes to bits, then to Mbps)
            let speedInMbps = (Double(self.uploadedBytes) * 8.0 / 1_000_000.0) / elapsedTime

            DispatchQueue.main.async {
                self.uploadResult?(error == nil ? speedInMbps : 0.0)
                self.uploadResult = nil
            }
        }

        task.resume()
    }

    // MARK: - URLSessionDataDelegate methods

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        downloadedBytes += data.count
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let stopTime = CFAbsoluteTimeGetCurrent()
        let elapsedTime = max(stopTime - downloadStartTime, 0.001) // Avoid division by zero

        // Calculate speed in Mbps (bytes to bits, then to Mbps)
        let speedInMbps = (Double(downloadedBytes) * 8.0 / 1_000_000.0) / elapsedTime

        DispatchQueue.main.async {
            self.downloadResult?(error == nil ? speedInMbps : 0.0)
            self.downloadResult = nil
        }
    }
}