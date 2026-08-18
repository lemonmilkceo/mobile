package app.privatematching.baeandlee_app

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private var pushSink: EventChannel.EventSink? = null

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    window.setFlags(
      WindowManager.LayoutParams.FLAG_SECURE,
      WindowManager.LayoutParams.FLAG_SECURE,
    )
  }

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "app.privatematching.baeandlee/invite",
    ).setMethodCallHandler { call, result ->
      if (call.method == "getLaunchInviteCode") {
        val extras = intent?.extras
        val fromExtras =
          extras?.getString("code") ?: extras?.getString("invite")
        val data = intent?.data
        val fromUri =
          data?.getQueryParameter("code") ?: data?.getQueryParameter("invite")
        result.success(fromExtras ?: fromUri)
      } else {
        result.notImplemented()
      }
    }

    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "app.privatematching.baeandlee/push",
    ).setMethodCallHandler { call, result ->
      if (call.method == "getLaunchInterestId") {
        result.success(interestIdFrom(intent))
      } else {
        result.notImplemented()
      }
    }

    EventChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "app.privatematching.baeandlee/push_opens",
    ).setStreamHandler(
      object : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
          pushSink = events
          interestIdFrom(intent)?.let { events.success(it) }
        }

        override fun onCancel(arguments: Any?) {
          pushSink = null
        }
      },
    )
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    setIntent(intent)
    interestIdFrom(intent)?.let { pushSink?.success(it) }
  }

  private fun interestIdFrom(intent: Intent?): String? {
    val extras: Bundle = intent?.extras ?: return null
    val keys = listOf("interest_id", "gcm.n.interest_id", "google.interest_id")
    for (key in keys) {
      extraString(extras, key)?.let { return it }
    }
    for (key in extras.keySet()) {
      if (key.equals("interest_id", ignoreCase = true)) {
        extraString(extras, key)?.let { return it }
      }
    }
    return null
  }

  private fun extraString(extras: Bundle, key: String): String? {
    extras.getString(key)?.trim()?.takeIf { it.isNotEmpty() }?.let { return it }
    val raw = extras.get(key) ?: return null
    val value = raw.toString().trim()
    if (value.isEmpty() || value == "null") return null
    return value
  }
}
