package com.example.splitwise

import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.example.splitwise/settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationSettings" -> {
                    try {
                        val intent = Intent().apply {
                            action = Settings.ACTION_APP_NOTIFICATION_SETTINGS
                            putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("UNAVAILABLE", "Could not open settings", e.message)
                    }
                }
                "getSupportDeviceInfo" -> {
                    val brand = Build.BRAND.replaceFirstChar { char ->
                        char.titlecase()
                    }
                    val device = "$brand ${Build.MODEL}".trim()
                    val operatingSystem = "Android API ${Build.VERSION.SDK_INT}"
                    result.success(
                        mapOf(
                            "device" to device,
                            "operatingSystem" to operatingSystem,
                        ),
                    )
                }
                else -> result.notImplemented()
            }
        }
    }
}
