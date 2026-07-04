package com.fzy.pangbao

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Shader
import org.json.JSONArray

object PangbaoWidgetBitmaps {
    fun gradientBackground(startColor: Int, endColor: Int, width: Int, height: Int, radiusPx: Float): Bitmap {
        val bmp = Bitmap.createBitmap(width.coerceAtLeast(1), height.coerceAtLeast(1), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        paint.shader = LinearGradient(
            0f, 0f, width.toFloat(), height.toFloat(),
            startColor, endColor, Shader.TileMode.CLAMP,
        )
        canvas.drawRoundRect(RectF(0f, 0f, width.toFloat(), height.toFloat()), radiusPx, radiusPx, paint)
        return bmp
    }

    fun sparkline(points: JSONArray, lineColor: Int, width: Int, height: Int): Bitmap {
        val bmp = Bitmap.createBitmap(width.coerceAtLeast(1), height.coerceAtLeast(1), Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bmp)
        if (points.length() < 2) return bmp

        var max = 0.0
        for (i in 0 until points.length()) {
            max = maxOf(max, points.optDouble(i, 0.0))
        }
        if (max <= 0.0) max = 1.0

        val padX = width * 0.06f
        val padY = height * 0.18f
        val innerW = width - padX * 2
        val innerH = height - padY * 2
        val step = innerW / (points.length() - 1).coerceAtLeast(1)

        val path = Path()
        for (i in 0 until points.length()) {
            val v = points.optDouble(i, 0.0)
            val x = padX + step * i
            val y = padY + innerH - (v / max * innerH).toFloat()
            if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
        }

        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = lineColor
            style = Paint.Style.STROKE
            strokeWidth = 3f
            strokeCap = Paint.Cap.ROUND
            strokeJoin = Paint.Join.ROUND
        }
        canvas.drawPath(path, paint)
        return bmp
    }
}
