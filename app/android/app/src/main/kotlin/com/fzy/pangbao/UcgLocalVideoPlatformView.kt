package com.fzy.pangbao

import android.content.Context
import android.net.Uri
import android.view.View
import android.widget.MediaController
import android.widget.VideoView
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.platform.PlatformView

class UcgLocalVideoPlatformView(
    context: Context,
    private val filePath: String?,
    private val contentUri: String?,
    private val events: EventChannel.EventSink?,
) : PlatformView {
    private val videoView = VideoView(context)
    private val mediaController = MediaController(context)

    init {
        mediaController.setAnchorView(videoView)
        videoView.setMediaController(mediaController)
        val uri = resolveUri()
        if (uri == null) {
            events?.error("invalid_source", "missing video source", null)
        } else {
            videoView.setVideoURI(uri)
            videoView.setOnPreparedListener { mp ->
                mp.isLooping = false
                events?.success(mapOf("event" to "prepared"))
                videoView.start()
            }
            videoView.setOnErrorListener { _, what, extra ->
                events?.error("playback_error", "what=$what extra=$extra", null)
                true
            }
            videoView.setOnCompletionListener {
                events?.success(mapOf("event" to "completed"))
            }
        }
    }

    private fun resolveUri(): Uri? {
        if (!contentUri.isNullOrEmpty()) return Uri.parse(contentUri)
        if (!filePath.isNullOrEmpty()) {
            return if (filePath.startsWith("content://") || filePath.startsWith("file://")) {
                Uri.parse(filePath)
            } else {
                Uri.fromFile(java.io.File(filePath))
            }
        }
        return null
    }

    override fun getView(): View = videoView

    override fun dispose() {
        videoView.stopPlayback()
    }
}
