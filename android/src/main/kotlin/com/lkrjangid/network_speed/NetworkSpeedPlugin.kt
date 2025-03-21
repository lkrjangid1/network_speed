package com.lkrjangid.network_speed

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.Handler
import android.os.Looper
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException
import java.net.URL
import java.util.concurrent.Executors
import kotlin.math.max

/** NetworkSpeedPlugin */
class NetworkSpeedPlugin: FlutterPlugin, MethodCallHandler {
  private lateinit var channel : MethodChannel
  private lateinit var context: Context
  private val executor = Executors.newFixedThreadPool(2)
  private val mainHandler = Handler(Looper.getMainLooper())

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "network_speed")
    context = flutterPluginBinding.applicationContext
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "getCurrentNetworkType" -> {
        executor.execute {
          val networkType = getCurrentNetworkType()
          mainHandler.post {
            result.success(networkType)
          }
        }
      }
      "getDownloadSpeed" -> {
        executor.execute {
          val downloadSpeed = getDownloadSpeed()
          mainHandler.post {
            result.success(downloadSpeed)
          }
        }
      }
      "getUploadSpeed" -> {
        executor.execute {
          val uploadSpeed = getUploadSpeed()
          mainHandler.post {
            result.success(uploadSpeed)
          }
        }
      }
      "getCurrentNetworkSpeed" -> {
        executor.execute {
          val networkSpeed = getCurrentNetworkSpeed()
          mainHandler.post {
            result.success(networkSpeed)
          }
        }
      }
      "runDownloadSpeedTest" -> {
        val testFileUrl = call.argument<String>("testFileUrl") ?: "https://filesamples.com/samples/document/txt/sample3.txt"
        executor.execute {
          val speed = runDownloadSpeedTest(testFileUrl)
          mainHandler.post {
            result.success(speed)
          }
        }
      }
      "runUploadSpeedTest" -> {
        val testFileUrl = call.argument<String>("testFileUrl") ?: "https://httpbin.org/post"
        executor.execute {
          val speed = runUploadSpeedTest(testFileUrl)
          mainHandler.post {
            result.success(speed)
          }
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun getCurrentNetworkType(): String {
    val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    val networkCapabilities = connectivityManager.getNetworkCapabilities(connectivityManager.activeNetwork)

    return if (networkCapabilities != null) {
      when {
        networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
        networkCapabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "mobile"
        else -> "unknown"
      }
    } else {
      "unknown"
    }
  }

  private fun getDownloadSpeed(): Double {
    val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    val networkCapabilities = connectivityManager.getNetworkCapabilities(connectivityManager.activeNetwork)

    return if (networkCapabilities != null) {
      // Convert from Kbps to Mbps
      networkCapabilities.getLinkDownstreamBandwidthKbps() / 1000.0
    } else {
      0.0
    }
  }

  private fun getUploadSpeed(): Double {
    val connectivityManager = context.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
    val networkCapabilities = connectivityManager.getNetworkCapabilities(connectivityManager.activeNetwork)

    return if (networkCapabilities != null) {
      // Convert from Kbps to Mbps
      networkCapabilities.getLinkUpstreamBandwidthKbps() / 1000.0
    } else {
      0.0
    }
  }

  private fun getWifiSignalStrength(): Int {
    val networkType = getCurrentNetworkType()

    return if (networkType == "wifi") {
      val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as WifiManager
      val linkSpeed = wifiManager.connectionInfo.rssi
      WifiManager.calculateSignalLevel(linkSpeed, 5)
    } else {
      -1
    }
  }

  private fun getCurrentNetworkSpeed(): Map<String, Any> {
    val networkType = getCurrentNetworkType()
    val downloadSpeed = getDownloadSpeed()
    val uploadSpeed = getUploadSpeed()
    val signalStrength = if (networkType == "wifi") getWifiSignalStrength() else -1

    return mapOf(
            "networkType" to networkType,
            "downloadSpeed" to downloadSpeed,
            "uploadSpeed" to uploadSpeed,
            "signalStrength" to signalStrength
    )
  }

  private fun runDownloadSpeedTest(testFileUrl: String): Double {
    try {
      val url = URL(testFileUrl)
      val startTime = System.currentTimeMillis()
      val connection = url.openConnection()
      connection.connectTimeout = 10000
      connection.readTimeout = 10000

      // Set User-Agent to avoid 403 errors
      connection.setRequestProperty("User-Agent", "Mozilla/5.0")

      val inputStream = connection.getInputStream()
      val buffer = ByteArray(1024)
      var bytesRead: Int
      var totalBytesRead = 0

      while (inputStream.read(buffer).also { bytesRead = it } != -1) {
        totalBytesRead += bytesRead
      }

      inputStream.close()

      val endTime = System.currentTimeMillis()
      val duration = max(1, endTime - startTime) / 1000.0 // Convert to seconds

      // Calculate speed in Mbps (bytes to bits, then to Mbps)
      return (totalBytesRead * 8.0 / 1_000_000.0) / duration
    } catch (e: IOException) {
      e.printStackTrace()
      // If standard test file fails, try a fallback URL
      if (testFileUrl != "https://httpbin.org/get") {
        return runDownloadSpeedTest("https://httpbin.org/get")
      }
      return 0.0
    }
  }

  private fun runUploadSpeedTest(testFileUrl: String): Double {
    try {
      val url = URL(testFileUrl)
      val connection = url.openConnection()
      connection.doOutput = true
      connection.setRequestProperty("Content-Type", "application/octet-stream")
      connection.connectTimeout = 10000
      connection.readTimeout = 10000

      // Create a test data payload (1MB)
      val testData = ByteArray(1024 * 1024)

      val startTime = System.currentTimeMillis()
      val outputStream = connection.getOutputStream()
      outputStream.write(testData)
      outputStream.flush()
      outputStream.close()

      // Read the response
      val inputStream = connection.getInputStream()
      inputStream.close()

      val endTime = System.currentTimeMillis()
      val duration = max(1, endTime - startTime) / 1000.0 // Convert to seconds

      // Calculate speed in Mbps (bytes to bits, then to Mbps)
      return (testData.size * 8.0 / 1_000_000.0) / duration
    } catch (e: IOException) {
      e.printStackTrace()
      return 0.0
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    executor.shutdown()
  }
}