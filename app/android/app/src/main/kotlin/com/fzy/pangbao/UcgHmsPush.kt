package com.fzy.pangbao

import android.content.Context
import com.huawei.hms.aaid.HmsInstanceId
import com.huawei.hms.common.ApiException

/**
 * HMS Push Kit token acquisition. Requires [BuildConfig.UCG_HMS_APP_ID] or agconnect-services.json.
 */
object UcgHmsPush {
    @Volatile
    private var started = false

    fun start(context: Context) {
        if (started) return
        val appId = BuildConfig.UCG_HMS_APP_ID.trim()
        if (appId.isEmpty()) return
        started = true
        requestToken(context.applicationContext)
    }

    fun requestToken(context: Context) {
        val appId = BuildConfig.UCG_HMS_APP_ID.trim()
        if (appId.isEmpty()) return
        Thread {
            try {
                val token = HmsInstanceId.getInstance(context).getToken(appId, "HCM")
                if (!token.isNullOrBlank()) {
                    UcgPushBridge.publishToken("hms", token.trim())
                }
            } catch (_: ApiException) {
            } catch (_: Exception) {
            }
        }.start()
    }
}
