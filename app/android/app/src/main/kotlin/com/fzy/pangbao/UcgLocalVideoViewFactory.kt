package com.fzy.pangbao

import android.content.Context
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class UcgLocalVideoViewFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val params = args as? Map<String, Any?>
        val filePath = params?.get("filePath") as? String
        val contentUri = params?.get("contentUri") as? String
        return UcgLocalVideoPlatformView(context, filePath, contentUri, UcgLocalVideoEvents.sink)
    }
}
