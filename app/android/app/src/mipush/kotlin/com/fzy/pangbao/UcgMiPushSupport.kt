package com.fzy.pangbao

import android.app.ActivityManager
import android.content.Context
import android.os.Process
import com.xiaomi.mipush.sdk.MiPushClient
import com.xiaomi.mipush.sdk.Region

object UcgMiPushSupport {
    @Volatile
    private var started = false

    fun start(context: Context) {
        if (started || !BuildConfig.UCG_MIPUSH_ENABLED) return
        if (!isMainProcess(context)) return
        val appId = BuildConfig.UCG_MIPUSH_APP_ID.trim()
        val appKey = BuildConfig.UCG_MIPUSH_APP_KEY.trim()
        if (appId.isEmpty() || appKey.isEmpty()) return
        started = true
        MiPushClient.setRegion(context, parseRegion(BuildConfig.UCG_MIPUSH_REGION))
        MiPushClient.registerPush(context, appId, appKey)
        publishExistingRegId(context)
    }

    fun requestToken(context: Context) {
        if (!BuildConfig.UCG_MIPUSH_ENABLED) return
        start(context)
        publishExistingRegId(context)
    }

    private fun publishExistingRegId(context: Context) {
        val regId = MiPushClient.getRegId(context)?.trim().orEmpty()
        if (regId.isNotEmpty()) {
            UcgPushBridge.publishToken("mipush", regId)
        }
    }

    private fun parseRegion(raw: String): Region {
        return when (raw.trim().lowercase()) {
            "global", "singapore" -> Region.Global
            "europe" -> Region.Europe
            "russia" -> Region.Russia
            "india" -> Region.India
            else -> Region.China
        }
    }

    private fun isMainProcess(context: Context): Boolean {
        val mainProcessName = context.applicationInfo.processName
        val myPid = Process.myPid()
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return am.runningAppProcesses?.any {
            it.pid == myPid && mainProcessName == it.processName
        } == true
    }
}
