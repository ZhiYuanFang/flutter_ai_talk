package com.fzy.pangbao

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Vendor push token bridge (APNs on iOS; HMS / MiPush on supported Android OEMs).
 * No FCM. Non-Huawei/Xiaomi Android returns null token → client skips register.
 */
object UcgPushBridge {
    private const val POST_NOTIFICATIONS_REQUEST = 9101

    @Volatile
    var cachedToken: String? = null

    @Volatile
    var cachedChannel: String? = null

    @Volatile
    var tokenSink: MethodChannel? = null

    fun handle(call: MethodCall, result: MethodChannel.Result, activity: Activity) {
        when (call.method) {
            "requestPermission" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    val granted = ContextCompat.checkSelfPermission(
                        activity,
                        Manifest.permission.POST_NOTIFICATIONS,
                    ) == PackageManager.PERMISSION_GRANTED
                    if (!granted) {
                        ActivityCompat.requestPermissions(
                            activity,
                            arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                            POST_NOTIFICATIONS_REQUEST,
                        )
                        result.success(false)
                        return
                    }
                }
                result.success(true)
            }
            "getToken" -> {
                val channel = call.argument<String>("channel")?.trim()?.lowercase()
                if (channel.isNullOrEmpty()) {
                    result.success(null)
                    return
                }
                val detected = detectChannel()
                if (detected == null || detected != channel) {
                    result.success(null)
                    return
                }
                if (cachedChannel == channel && !cachedToken.isNullOrBlank()) {
                    result.success(cachedToken)
                    return
                }
                UcgPushInitializer.refreshToken(activity, channel)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun detectChannel(): String? {
        val m = Build.MANUFACTURER.lowercase()
        val brand = Build.BRAND.lowercase()
        return when {
            m.contains("huawei") || m.contains("honor") ||
                brand.contains("huawei") || brand.contains("honor") -> "hms"
            m.contains("xiaomi") || m.contains("redmi") ||
                brand.contains("xiaomi") || brand.contains("redmi") -> "mipush"
            else -> null
        }
    }

    fun publishToken(channel: String, token: String) {
        cachedChannel = channel
        cachedToken = token
        tokenSink?.invokeMethod(
            "onTokenRefresh",
            mapOf("channel" to channel, "token" to token),
        )
    }
}
