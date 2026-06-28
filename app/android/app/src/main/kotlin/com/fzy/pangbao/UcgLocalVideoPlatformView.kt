package com.fzy.pangbao

import android.content.Context
import android.graphics.Color
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Build
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.MediaController
import android.widget.VideoView
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.platform.PlatformView

class UcgLocalVideoPlatformView(
    context: Context,
    private val filePath: String?,
    private val contentUri: String?,
    private val hintDisplayWidth: Int?,
    private val hintDisplayHeight: Int?,
    private val events: EventChannel.EventSink?,
) : PlatformView {
    private val container = FrameLayout(context).apply {
        setBackgroundColor(Color.BLACK)
    }
    private val videoView = VideoView(context)
    private val mediaController = MediaController(context)
    private var videoWidth = 0
    private var videoHeight = 0
    private var prepared = false
    private var uriBound = false
    private var pendingUri: Uri? = null

    init {
        // PlatformView + SurfaceView：不得从 0×0 prepare，否则 Surface 无法恢复（黑屏）。
        container.addView(
            videoView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
                Gravity.CENTER,
            ),
        )
        mediaController.setAnchorView(videoView)
        videoView.setMediaController(mediaController)
        container.addOnLayoutChangeListener { _, _, _, _, _, _, _, _, _ ->
            if (!uriBound) {
                bindVideoUriWhenSized()
            }
            if (prepared) {
                layoutVideoView()
            }
        }

        videoView.setOnPreparedListener { mp ->
            mp.isLooping = false
            val codedW = mp.videoWidth
            val codedH = mp.videoHeight
            val uri = pendingUri ?: resolveUri()
            val (displayW, displayH) = resolveDisplaySize(uri, codedW, codedH)
            videoWidth = displayW
            videoHeight = displayH
            prepared = true
            layoutVideoView()
            events?.success(mapOf("event" to "prepared"))
            videoView.post { videoView.start() }
        }
        videoView.setOnErrorListener { _, what, extra ->
            events?.error("playback_error", "what=$what extra=$extra", null)
            true
        }
        videoView.setOnCompletionListener {
            events?.success(mapOf("event" to "completed"))
        }

        val uri = resolveUri()
        if (uri == null) {
            events?.error("invalid_source", "missing video source", null)
        } else {
            pendingUri = uri
            bindVideoUriWhenSized()
        }
    }

    private fun bindVideoUriWhenSized() {
        val uri = pendingUri ?: return
        if (uriBound) return
        if (container.width <= 0 || container.height <= 0) {
            container.post { bindVideoUriWhenSized() }
            return
        }
        uriBound = true
        videoView.setVideoURI(uri)
    }

    private fun resolveDisplaySize(uri: Uri?, codedW: Int, codedH: Int): Pair<Int, Int> {
        val hintW = hintDisplayWidth
        val hintH = hintDisplayHeight
        if (hintW != null && hintH != null && hintW > 0 && hintH > 0) {
            return hintW to hintH
        }
        if (uri != null) {
            return displaySizeForUri(uri, codedW, codedH)
        }
        return codedW to codedH
    }

    private fun readVideoRotation(uri: Uri): Int {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(container.context, uri)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION)
                    ?.toIntOrNull() ?: 0
            } else {
                0
            }
        } catch (_: Exception) {
            0
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
            }
        }
    }

    private fun displaySizeForUri(uri: Uri, codedW: Int, codedH: Int): Pair<Int, Int> {
        if (codedW <= 0 || codedH <= 0) return codedW to codedH
        val rotation = readVideoRotation(uri)
        return if (rotation == 90 || rotation == 270) {
            codedH to codedW
        } else {
            codedW to codedH
        }
    }

    private fun layoutVideoView() {
        val containerW = container.width
        val containerH = container.height
        if (containerW <= 0 || containerH <= 0) {
            container.post { layoutVideoView() }
            return
        }

        val params = if (videoWidth <= 0 || videoHeight <= 0) {
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
                Gravity.CENTER,
            )
        } else {
            val videoAspect = videoWidth.toFloat() / videoHeight.toFloat()
            val containerAspect = containerW.toFloat() / containerH.toFloat()
            val (displayW, displayH) = if (videoAspect > containerAspect) {
                val w = containerW
                val h = (containerW / videoAspect).toInt().coerceAtLeast(1)
                w to h
            } else {
                val h = containerH
                val w = (containerH * videoAspect).toInt().coerceAtLeast(1)
                w to h
            }
            FrameLayout.LayoutParams(displayW, displayH, Gravity.CENTER)
        }

        videoView.layoutParams = params
        videoView.requestLayout()
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

    override fun getView(): View = container

    override fun dispose() {
        videoView.stopPlayback()
    }
}
