package com.fzy.pangbao

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.content.FileProvider
import androidx.core.splashscreen.SplashScreen.Companion.installSplashScreen
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File

class MainActivity : FlutterActivity() {
    private val installerChannel = "com.fzy.pangbao/installer"
    private val nativeSplashChannel = "com.fzy.pangbao/native_splash"
    private val localVideoChannel = "com.fzy.pangbao/local_video"
    private val pushClickChannelName = "com.fzy.pangbao/push_click"
    private var pushClickChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        val splash = installSplashScreen()
        splash.setKeepOnScreenCondition { KeepNativeSplash.visible }
        // 冷启动点击可能早于 Dart 监听；先记下 bizType。
        capturePushBizType(intent)
        // 与 Go push_hms.go 的 channelId=push_default 对齐，供 HMS 可见通知落托盘
        ensurePushNotificationChannel()
        super.onCreate(savedInstanceState)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val biz = capturePushBizType(intent)
        if (!biz.isNullOrEmpty()) {
            pushClickChannel?.invokeMethod("onPushClick", biz)
        }
    }

    /** Android 8+ 系统通知渠道；id 必须与服务端 HMS android.notification.channelId 一致。 */
    private fun ensurePushNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            PUSH_NOTIFICATION_CHANNEL_ID,
            getString(R.string.push_notification_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.push_notification_channel_desc)
            enableVibration(true)
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        /** 与 go_ai_talk internal/services/push/push_hms.go 硬编码一致，勿改。 */
        const val PUSH_NOTIFICATION_CHANNEL_ID = "push_default"

        /** Dart 监听就绪前暂存的点击 bizType。 */
        var pendingPushBizType: String? = null

        fun readBizType(intent: Intent?): String? {
            if (intent == null) return null
            val direct = intent.getStringExtra("bizType")?.trim().orEmpty()
            if (direct.isNotEmpty()) return direct
            val extras = intent.extras ?: return null
            for (key in extras.keySet()) {
                val raw = extras.get(key)?.toString()?.trim().orEmpty()
                if (!raw.startsWith("{")) continue
                try {
                    val biz = JSONObject(raw).optString("bizType").trim()
                    if (biz.isNotEmpty()) return biz
                } catch (_: Exception) {
                    // 非 JSON 的 extras 忽略
                }
            }
            return null
        }
    }

    private fun capturePushBizType(intent: Intent?): String? {
        val biz = readBizType(intent) ?: return null
        pendingPushBizType = biz
        return biz
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pushClickChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            pushClickChannelName,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialPushClick" -> {
                        val biz = pendingPushBizType
                        pendingPushBizType = null
                        result.success(biz)
                    }
                    else -> result.notImplemented()
                }
            }
        }
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "$localVideoChannel/events")
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    UcgLocalVideoEvents.sink = events
                }

                override fun onCancel(arguments: Any?) {
                    UcgLocalVideoEvents.sink = null
                }
            })
        flutterEngine
            .platformViewsController
            .registry
            .registerViewFactory(
                "ucg-local-video",
                UcgLocalVideoViewFactory(),
            )
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, localVideoChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "openSystemPlayer" -> {
                    val videoUrl = call.argument<String>("videoUrl")
                    val filePath = call.argument<String>("filePath")
                    val contentUri = call.argument<String>("contentUri")
                    val uri = resolveVideoUri(videoUrl, filePath, contentUri)
                    if (uri == null) {
                        result.error("invalid_source", "missing video source", null)
                        return@setMethodCallHandler
                    }
                    try {
                        startVideoViewIntent(uri)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("open_failed", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, nativeSplashChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "hide" -> {
                    KeepNativeSplash.visible = false
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, installerChannel).setMethodCallHandler { call, result ->
            when (call.method) {
                "canRequestPackageInstalls" -> {
                    val ok = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        packageManager.canRequestPackageInstalls()
                    } else {
                        true
                    }
                    result.success(ok)
                }
                "openInstallPermissionSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                            Uri.parse("package:$packageName"),
                        )
                        startActivity(intent)
                    }
                    result.success(null)
                }
                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path.isNullOrEmpty()) {
                        result.error("invalid_argument", "missing path", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val file = File(path)
                        if (!file.exists()) {
                            result.error("not_found", "apk not found", null)
                            return@setMethodCallHandler
                        }
                        val uri = FileProvider.getUriForFile(
                            this,
                            "$packageName.fileprovider",
                            file,
                        )
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("install_failed", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun resolveVideoUri(videoUrl: String?, filePath: String?, contentUri: String?): Uri? {
        if (!videoUrl.isNullOrEmpty()) {
            return Uri.parse(videoUrl)
        }
        if (!contentUri.isNullOrEmpty()) return Uri.parse(contentUri)
        if (filePath.isNullOrEmpty()) return null
        if (filePath.startsWith("content://") || filePath.startsWith("file://")) {
            return Uri.parse(filePath)
        }
        val file = File(filePath)
        if (!file.exists()) return null
        return FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
    }

    private fun startVideoViewIntent(uri: Uri) {
        val candidates = listOf(
            Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "video/*")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            },
            Intent(Intent.ACTION_VIEW, uri).apply {
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            },
        )
        for (intent in candidates) {
            if (intent.resolveActivity(packageManager) != null) {
                startActivity(intent)
                return
            }
        }
        val fallback = candidates.first()
        startActivity(Intent.createChooser(fallback, null))
    }
}

private object KeepNativeSplash {
    @Volatile
    var visible: Boolean = true
}

object UcgLocalVideoEvents {
    @Volatile
    var sink: EventChannel.EventSink? = null
}
