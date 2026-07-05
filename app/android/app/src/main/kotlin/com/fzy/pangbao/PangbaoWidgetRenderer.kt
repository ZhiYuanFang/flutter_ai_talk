package com.fzy.pangbao

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.util.Log
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.time.Instant
import java.time.ZoneId
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.time.format.DateTimeFormatterBuilder
import java.time.temporal.ChronoField
import java.time.temporal.ChronoUnit
import kotlin.math.max

private enum class WidgetLayoutKind { SMALL, MEDIUM, LARGE }

private data class WidgetVisualScale(
    val headerSp: Float,
    val messageSp: Float,
    val heroLogoDp: Int,
    val heroNameSp: Float,
    val heroTimeSp: Float,
    val recentLogoDp: Int,
    val recentNameSp: Float,
    val recentTimeSp: Float,
    val compactHeader: Boolean,
)

object PangbaoWidgetRenderer {
    private const val TAG = "PangbaoWidget"
    const val PAYLOAD_KEY = "widgetPayload"

    private val localDateTimeParser = DateTimeFormatterBuilder()
        .append(DateTimeFormatter.ISO_LOCAL_DATE)
        .optionalStart()
        .appendLiteral('T')
        .appendValue(ChronoField.HOUR_OF_DAY, 2)
        .appendLiteral(':')
        .appendValue(ChronoField.MINUTE_OF_HOUR, 2)
        .optionalStart()
        .appendLiteral(':')
        .appendValue(ChronoField.SECOND_OF_MINUTE, 2)
        .optionalStart()
        .appendFraction(ChronoField.NANO_OF_SECOND, 0, 9, true)
        .optionalEnd()
        .optionalEnd()
        .optionalEnd()
        .toFormatter()

    fun updateAll(context: Context, clazz: Class<*>, layoutId: Int) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, clazz))
        for (id in ids) {
            updateAppWidget(context, manager, id, layoutId)
        }
    }

    fun updateAppWidget(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        layoutId: Int,
    ) {
        try {
            renderAppWidget(context, manager, appWidgetId, layoutId)
        } catch (e: Exception) {
            Log.e(TAG, "updateAppWidget id=$appWidgetId failed", e)
            renderFallback(context, manager, appWidgetId, layoutId)
        }
    }

    private fun layoutKind(layoutId: Int): WidgetLayoutKind = when (layoutId) {
        R.layout.widget_pangbao_small -> WidgetLayoutKind.SMALL
        R.layout.widget_pangbao_medium -> WidgetLayoutKind.MEDIUM
        else -> WidgetLayoutKind.LARGE
    }

    private fun resolveScale(kind: WidgetLayoutKind): WidgetVisualScale = when (kind) {
        WidgetLayoutKind.SMALL -> WidgetVisualScale(
            headerSp = 14f,
            messageSp = 14f,
            heroLogoDp = 48,
            heroNameSp = 11f,
            heroTimeSp = 10f,
            recentLogoDp = 36,
            recentNameSp = 10f,
            recentTimeSp = 9f,
            compactHeader = true,
        )
        WidgetLayoutKind.MEDIUM -> WidgetVisualScale(
            headerSp = 14f,
            messageSp = 13f,
            heroLogoDp = 56,
            heroNameSp = 14f,
            heroTimeSp = 12f,
            recentLogoDp = 36,
            recentNameSp = 10f,
            recentTimeSp = 9f,
            compactHeader = true,
        )
        WidgetLayoutKind.LARGE -> WidgetVisualScale(
            headerSp = 16f,
            messageSp = 14f,
            heroLogoDp = 52,
            heroNameSp = 14f,
            heroTimeSp = 12f,
            recentLogoDp = 36,
            recentNameSp = 10f,
            recentTimeSp = 9f,
            compactHeader = false,
        )
    }

    private fun renderAppWidget(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        layoutId: Int,
    ) {
        val views = RemoteViews(context.packageName, layoutId)
        val kind = layoutKind(layoutId)
        val scale = resolveScale(kind)
        val raw = HomeWidgetPlugin.getData(context).getString(PAYLOAD_KEY, null)
        Log.d(TAG, "render id=$appWidgetId kind=$kind payloadLen=${raw?.length ?: 0}")
        val root = if (raw.isNullOrBlank()) null else try {
            JSONObject(raw)
        } catch (_: Exception) {
            null
        }

        val visual = root?.optJSONObject("visual")
        applyShellBackground(context, views, visual, kind)

        val state = root?.optString("state", "empty") ?: "empty"
        val message = root?.optString("message", "打开胖宝记录") ?: "打开胖宝记录"
        val header = root?.optJSONObject("header")
        val textPrimary = parseColor(visual?.optString("textPrimary", "#3D454C"))
        val textSecondary = parseColor(visual?.optString("textSecondary", "#7A8690"))

        hideContentSections(views, kind)

        val showHeader = header != null && state != "empty"
        views.setViewVisibility(R.id.widget_header_row, if (showHeader) View.VISIBLE else View.GONE)
        if (showHeader) {
            views.setTextViewText(
                R.id.widget_header_text,
                formatHeaderLine(header!!, scale.compactHeader),
            )
            views.setTextColor(R.id.widget_header_text, textPrimary)
            views.setTextViewTextSize(R.id.widget_header_text, TypedValue.COMPLEX_UNIT_SP, scale.headerSp)
        }

        views.setViewVisibility(R.id.widget_message, View.GONE)

        when (state) {
            "loading", "empty" -> {
                views.setViewVisibility(R.id.widget_message, View.VISIBLE)
                views.setTextViewText(R.id.widget_message, message)
                views.setTextColor(R.id.widget_message, textSecondary)
                views.setTextViewTextSize(R.id.widget_message, TypedValue.COMPLEX_UNIT_SP, scale.messageSp)
            }
            else -> {
                val hero = root?.optJSONObject("hero")
                val recent = root?.optJSONArray("recentLast") ?: JSONArray()
                val tip = root?.optJSONObject("tip")
                var hasContent = false

                if ((kind == WidgetLayoutKind.LARGE || kind == WidgetLayoutKind.MEDIUM) && tip != null) {
                    val tipText = tip.optString("text", "").trim()
                    if (tipText.isNotEmpty()) {
                        views.setViewVisibility(R.id.widget_tip_section, View.VISIBLE)
                        views.setTextViewText(
                            R.id.widget_tip_title,
                            "🔊 ${context.getString(R.string.widget_section_tip)}",
                        )
                        views.setTextColor(R.id.widget_tip_title, textSecondary)
                        views.setTextViewText(R.id.widget_tip_text, tipText)
                        views.setTextColor(R.id.widget_tip_text, textPrimary)
                        hasContent = true
                    }
                }

                if (hero != null && kind != WidgetLayoutKind.MEDIUM) {
                    bindHero(context, views, hero, scale, textPrimary, textSecondary)
                    views.setViewVisibility(R.id.widget_hero_section, View.VISIBLE)
                    if (kind == WidgetLayoutKind.LARGE) {
                        views.setViewVisibility(R.id.widget_events_block, View.VISIBLE)
                    }
                    hasContent = true
                }

if (kind != WidgetLayoutKind.SMALL) {
    val filteredRecent = if (kind == WidgetLayoutKind.LARGE && hero != null) {
        val heroEventId = hero.optString("eventId")
        (0 until recent.length())
            .mapNotNull { recent.optJSONObject(it) }
            .filter { it.optString("eventId") != heroEventId }
    } else {
        (0 until recent.length())
            .mapNotNull { recent.optJSONObject(it) }
    }
    val slots = minOf(filteredRecent.size, 3)
    if (slots > 0) {
        views.setViewVisibility(R.id.widget_recent_section, View.VISIBLE)
        if (kind == WidgetLayoutKind.LARGE) {
            views.setViewVisibility(R.id.widget_events_block, View.VISIBLE)
        }
        for (i in 0 until 3) {
            if (i < slots) {
                bindRecentItem(
                    context,
                    views,
                    i,
                    filteredRecent[i],
                    scale,
                    kind,
                    textPrimary,
                    textSecondary,
                )
            } else {
                hideRecentSlot(views, i)
            }
        }
        hasContent = true
    }
}
                if (!hasContent) {
                    views.setViewVisibility(R.id.widget_message, View.VISIBLE)
                    views.setTextViewText(R.id.widget_message, message.ifBlank { "打开胖宝记录" })
                    views.setTextColor(R.id.widget_message, textSecondary)
                    views.setTextViewTextSize(R.id.widget_message, TypedValue.COMPLEX_UNIT_SP, scale.messageSp)
                }
            }
        }

        attachLaunchClick(context, views, appWidgetId, kind)
        manager.updateAppWidget(appWidgetId, views)
        Log.d(TAG, "updated id=$appWidgetId state=$state kind=$kind")
    }

    private fun hideContentSections(views: RemoteViews, kind: WidgetLayoutKind) {
        setOptionalVisibility(views, R.id.widget_tip_section, View.GONE)
        setOptionalVisibility(views, R.id.widget_events_block, View.GONE)
        setOptionalVisibility(views, R.id.widget_hero_section, View.GONE)
        setOptionalVisibility(views, R.id.widget_recent_section, View.GONE)
        for (i in 0..2) {
            recentContainerId(i)?.let { views.setViewVisibility(it, View.GONE) }
        }
    }

    private fun setOptionalVisibility(views: RemoteViews, id: Int, visibility: Int) {
        try {
            views.setViewVisibility(id, visibility)
        } catch (_: Exception) {
        }
    }

    private fun bindHero(
        context: Context,
        views: RemoteViews,
        row: JSONObject,
        scale: WidgetVisualScale,
        textPrimary: Int,
        textSecondary: Int,
    ) {
        bindTileLogo(context, views, R.id.widget_hero_logo, row.optString("logoFile", ""), scale.heroLogoDp)
        views.setTextViewText(R.id.widget_hero_name, row.optString("name", ""))
        views.setTextColor(R.id.widget_hero_name, textPrimary)
        views.setTextViewTextSize(R.id.widget_hero_name, TypedValue.COMPLEX_UNIT_SP, scale.heroNameSp)

        val subtitle = formatPredict(
            row.optString("nextAt", ""),
            row.optString("status", "upcoming"),
            compact = scale.compactHeader,
        )
        views.setTextViewText(R.id.widget_hero_time, subtitle)
        views.setTextColor(R.id.widget_hero_time, textSecondary)
        views.setTextViewTextSize(R.id.widget_hero_time, TypedValue.COMPLEX_UNIT_SP, scale.heroTimeSp)
    }

    private fun bindRecentItem(
        context: Context,
        views: RemoteViews,
        index: Int,
        row: JSONObject,
        scale: WidgetVisualScale,
        kind: WidgetLayoutKind,
        textPrimary: Int,
        textSecondary: Int,
    ) {
        val containerId = recentContainerId(index) ?: return
        val nameId = recentNameId(index) ?: return
        val timeId = recentTimeId(index) ?: return

        views.setViewVisibility(containerId, View.VISIBLE)
        val logoId = recentLogoId(index) ?: return
        bindTileLogo(context, views, logoId, row.optString("logoFile", ""), scale.recentLogoDp)
        views.setTextViewText(nameId, row.optString("name", ""))
        views.setTextColor(nameId, textPrimary)
        views.setTextViewTextSize(nameId, TypedValue.COMPLEX_UNIT_SP, scale.recentNameSp)

        val lastRaw = row.optString("lastAt", "")
        val timeText = if (lastRaw.isBlank()) {
            context.getString(R.string.widget_last_at_none)
        } else {
            formatLastAt(lastRaw)
        }
        views.setTextViewText(timeId, timeText)
        views.setTextColor(timeId, textSecondary)
        views.setTextViewTextSize(timeId, TypedValue.COMPLEX_UNIT_SP, scale.recentTimeSp)
    }

    private fun hideRecentSlot(views: RemoteViews, index: Int) {
        recentContainerId(index)?.let { views.setViewVisibility(it, View.GONE) }
    }

    private fun renderFallback(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        layoutId: Int,
    ) {
        val kind = layoutKind(layoutId)
        val scale = resolveScale(kind)
        val views = RemoteViews(context.packageName, layoutId)
        hideContentSections(views, kind)
        views.setViewVisibility(R.id.widget_header_row, View.GONE)
        views.setViewVisibility(R.id.widget_message, View.VISIBLE)
        views.setTextViewText(R.id.widget_message, "打开胖宝记录")
        views.setTextColor(R.id.widget_message, Color.parseColor("#7A8690"))
        views.setTextViewTextSize(R.id.widget_message, TypedValue.COMPLEX_UNIT_SP, scale.messageSp)
        applyShellBackground(context, views, null, kind)
        attachLaunchClick(context, views, appWidgetId, kind)
        manager.updateAppWidget(appWidgetId, views)
    }

    private fun attachLaunchClick(context: Context, views: RemoteViews, appWidgetId: Int, kind: WidgetLayoutKind) {
        val launchIntent = launchPendingIntent(context, appWidgetId)
        val clickTargets = mutableListOf(
            R.id.widget_root,
            R.id.widget_bg,
            R.id.widget_content,
            R.id.widget_header_row,
            R.id.widget_message,
        )
        if (kind != WidgetLayoutKind.MEDIUM) {
            clickTargets.add(R.id.widget_hero_section)
            clickTargets.add(R.id.widget_hero_row)
            clickTargets.add(R.id.widget_hero_logo)
            clickTargets.add(R.id.widget_hero_name)
            clickTargets.add(R.id.widget_hero_time)
        }
        if (kind == WidgetLayoutKind.LARGE) {
            clickTargets.add(R.id.widget_events_block)
            clickTargets.add(R.id.widget_tip_section)
            clickTargets.add(R.id.widget_tip_title)
            clickTargets.add(R.id.widget_tip_text)
            clickTargets.add(R.id.widget_section_upcoming_title)
        }
        if (kind != WidgetLayoutKind.SMALL) {
            clickTargets.add(R.id.widget_recent_section)
            clickTargets.add(R.id.widget_recent_row)
            clickTargets.add(R.id.widget_section_recent_title)
            for (i in 0..2) {
                recentContainerId(i)?.let { clickTargets.add(it) }
                recentLogoId(i)?.let { clickTargets.add(it) }
                recentNameId(i)?.let { clickTargets.add(it) }
                recentTimeId(i)?.let { clickTargets.add(it) }
            }
        }
        for (id in clickTargets) {
            views.setOnClickPendingIntent(id, launchIntent)
        }
    }

    private fun launchPendingIntent(context: Context, appWidgetId: Int): PendingIntent {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: Intent(context, MainActivity::class.java)
        intent.addFlags(
            Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP,
        )
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        return PendingIntent.getActivity(context, appWidgetId, intent, flags)
    }

    private fun applyShellBackground(
        context: Context,
        views: RemoteViews,
        visual: JSONObject?,
        kind: WidgetLayoutKind = WidgetLayoutKind.SMALL,
    ) {
        val start = parseColor(visual?.optString("shellGradientStart", "#B8DFF2"))
        val end = parseColor(visual?.optString("shellGradientEnd", "#E8F4FC"))
        val radiusDp = visual?.optInt("cornerRadius", 18) ?: 18
        val opacity = visual?.optDouble("shellOpacity", 0.7)?.toFloat() ?: 0.7f
        val radiusPx = dp(context, radiusDp.coerceAtLeast(0)).toFloat()
        val w = when (kind) {
            WidgetLayoutKind.LARGE -> dp(context, 320)
            WidgetLayoutKind.MEDIUM -> dp(context, 320)
            WidgetLayoutKind.SMALL -> dp(context, 110)
        }
        val h = when (kind) {
            WidgetLayoutKind.LARGE -> dp(context, 280)
            WidgetLayoutKind.MEDIUM -> dp(context, 110)
            WidgetLayoutKind.SMALL -> dp(context, 110)
        }
       
        val bmpOriginal = PangbaoWidgetBitmaps.gradientBackground(
            withAlpha(start, opacity),
            withAlpha(end, opacity),
            w,
            h,
            radiusPx,
        )
        views.setImageViewBitmap(R.id.widget_bg, bmpOriginal)
    }

    private fun withAlpha(color: Int, opacity: Float): Int {
        val a = (opacity.coerceIn(0f, 1f) * 255).toInt()
        return Color.argb(a, Color.red(color), Color.green(color), Color.blue(color))
    }

    private fun dp(context: Context, value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            context.resources.displayMetrics,
        ).toInt()
    }

    private fun bindTileLogo(
        context: Context,
        views: RemoteViews,
        logoId: Int,
        logoPath: String,
        logoDp: Int,
    ) {
        val size = dp(context, logoDp)
        if (logoPath.isNotBlank()) {
            val file = File(logoPath)
            if (file.exists()) {
                try {
                    val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
                    BitmapFactory.decodeFile(file.absolutePath, opts)
                    opts.inSampleSize = computeInSampleSize(opts.outWidth, opts.outHeight, size)
                    opts.inJustDecodeBounds = false
                    val decoded = BitmapFactory.decodeFile(file.absolutePath, opts)
                    if (decoded != null) {
                        val bmp = Bitmap.createScaledBitmap(decoded, size, size, true)
                        if (bmp != decoded) decoded.recycle()
                        views.setImageViewBitmap(logoId, bmp)
                        return
                    }
                } catch (_: Exception) {
                }
            }
        }
        views.setImageViewResource(logoId, R.drawable.widget_event_placeholder)
    }

    private fun computeInSampleSize(width: Int, height: Int, target: Int): Int {
        var sample = 1
        if (width <= 0 || height <= 0) return sample
        while (width / sample > target * 2 || height / sample > target * 2) {
            sample *= 2
        }
        return sample
    }

    private fun recentContainerId(index: Int): Int? = when (index) {
        0 -> R.id.widget_recent_0
        1 -> R.id.widget_recent_1
        2 -> R.id.widget_recent_2
        else -> null
    }

    private fun recentLogoId(index: Int): Int? = when (index) {
        0 -> R.id.widget_recent_0_logo
        1 -> R.id.widget_recent_1_logo
        2 -> R.id.widget_recent_2_logo
        else -> null
    }

    private fun recentNameId(index: Int): Int? = when (index) {
        0 -> R.id.widget_recent_0_name
        1 -> R.id.widget_recent_1_name
        2 -> R.id.widget_recent_2_name
        else -> null
    }

    private fun recentTimeId(index: Int): Int? = when (index) {
        0 -> R.id.widget_recent_0_time
        1 -> R.id.widget_recent_1_time
        2 -> R.id.widget_recent_2_time
        else -> null
    }

    private fun formatHeaderLine(header: JSONObject, compact: Boolean = false): String {
        val fallback = header.optString("displayLine", "")
        val birthRaw = header.optString("birthDate", "")
        val nickname = header.optString("nickname", "").ifBlank { "宝宝" }
        if (birthRaw.isBlank()) return fallback.ifBlank { nickname }
        return try {
            val birth = Instant.parse("${birthRaw}T00:00:00Z").atZone(ZoneId.systemDefault()).toLocalDate()
            val today = java.time.LocalDate.now(ZoneId.systemDefault())
            var months = (today.year - birth.year) * 12 + (today.monthValue - birth.monthValue)
            if (today.dayOfMonth < birth.dayOfMonth) months -= 1
            months = max(0, months)
            val nick = if (nickname.length > 6) nickname.take(6) + "…" else nickname
            if (compact) {
                val ageText = when {
                    months == 0 -> "未满1月"
                    months < 12 -> "${months}月"
                    months % 12 == 0 -> "${months / 12}岁"
                    else -> "${months / 12}岁${months % 12}月"
                }
                return "$nick·$ageText"
            }
            val ageText = when {
                months == 0 -> "不满1个月啦"
                months < 12 -> "${months}个月啦"
                months % 12 == 0 -> "${months / 12}岁啦"
                else -> "${months / 12}岁${months % 12}个月啦"
            }
            "$nick · $ageText"
        } catch (_: Exception) {
            fallback.ifBlank { nickname }
        }
    }

    private fun formatPredict(nextAtRaw: String, status: String, compact: Boolean = false): String {
        val next = parseInstant(nextAtRaw) ?: return "约稍后"
        val now = Instant.now()
        val overdue = status == "overdue" || next.isBefore(now)
        val diffMin = ChronoUnit.MINUTES.between(if (overdue) next else now, if (overdue) now else next).coerceAtLeast(0)
        if (compact) {
            return if (overdue) {
                when {
                    diffMin < 1 -> "超时1分"
                    diffMin < 60 -> "超时${diffMin}分"
                    diffMin < 60 * 24 -> "超时${diffMin / 60}时"
                    else -> "超时${diffMin / (60 * 24)}天"
                }
            } else {
                when {
                    diffMin < 1 -> "约1分"
                    diffMin < 60 -> "约${diffMin}分"
                    diffMin < 60 * 24 -> "约${diffMin / 60}时"
                    else -> "约${diffMin / (60 * 24)}天"
                }
            }
        }
        return if (overdue) {
            when {
                diffMin < 1 -> "已超时 · 约 1 分钟"
                diffMin < 60 -> "已超时 · 约 ${diffMin} 分钟"
                diffMin < 60 * 24 -> "已超时 · 约 ${diffMin / 60} 小时"
                else -> "已超时 · 约 ${diffMin / (60 * 24)} 天"
            }
        } else {
            when {
                diffMin < 1 -> "约 1 分钟后"
                diffMin < 60 -> "约 ${diffMin} 分钟后"
                diffMin < 60 * 24 -> "约 ${diffMin / 60} 小时后"
                else -> "约 ${diffMin / (60 * 24)} 天后"
            }
        }
    }

    private fun formatLastAt(lastAtRaw: String): String {
        val instant = parseInstant(lastAtRaw) ?: return "暂无"
        val zone = ZoneId.systemDefault()
        val local = instant.atZone(zone)
        val today = java.time.LocalDate.now(zone)
        val day = local.toLocalDate()
        val h = local.hour.toString().padStart(2, '0')
        val m = local.minute.toString().padStart(2, '0')
        return when {
            day == today -> "$h:$m"
            day == today.minusDays(1) -> "昨天 $h:$m"
            else -> "${day.monthValue}月${day.dayOfMonth}日"
        }
    }

    private fun parseInstant(raw: String): Instant? {
        if (raw.isBlank()) return null
        return try {
            Instant.parse(raw)
        } catch (_: Exception) {
            try {
                Instant.from(DateTimeFormatter.ISO_OFFSET_DATE_TIME.parse(raw))
            } catch (_: Exception) {
                try {
                    LocalDateTime.parse(raw, localDateTimeParser)
                        .atZone(ZoneId.systemDefault())
                        .toInstant()
                } catch (_: Exception) {
                    null
                }
            }
        }
    }

    private fun parseColor(raw: String?): Int {
        var s = raw?.trim().orEmpty()
        if (s.isEmpty()) s = "#5BA3E8"
        if (s.startsWith("#")) s = s.substring(1)
        return try {
            Color.parseColor("#${if (s.length == 8) s.substring(2) else s}")
        } catch (_: Exception) {
            Color.parseColor("#5BA3E8")
        }
    }
}
