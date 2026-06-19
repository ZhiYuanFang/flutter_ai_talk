package com.fzy.pangbao

import android.content.Context

/** No-op MiPush stub when MiPush_SDK_Client*.aar is absent from app/libs/. */
object UcgMiPushSupport {
    fun start(context: Context) {}

    fun requestToken(context: Context) {}
}
