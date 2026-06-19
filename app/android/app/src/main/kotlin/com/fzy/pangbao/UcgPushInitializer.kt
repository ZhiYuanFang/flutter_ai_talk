package com.fzy.pangbao

import android.content.Context

object UcgPushInitializer {
    fun start(context: Context) {
        when (UcgPushBridge.detectChannel()) {
            "hms" -> UcgHmsPush.start(context)
            "mipush" -> UcgMiPushSupport.start(context)
        }
    }

    fun refreshToken(context: Context, channel: String) {
        when (channel) {
            "hms" -> UcgHmsPush.requestToken(context)
            "mipush" -> UcgMiPushSupport.requestToken(context)
        }
    }
}
