package com.fzy.pangbao

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context

class PangbaoWidgetSmallProvider : AppWidgetProvider() {
    override fun onEnabled(context: Context) {
        PangbaoWidgetRenderer.updateAll(
            context, PangbaoWidgetSmallProvider::class.java, R.layout.widget_pangbao_small,
        )
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            PangbaoWidgetRenderer.updateAppWidget(
                context, appWidgetManager, id, R.layout.widget_pangbao_small,
            )
        }
    }

    override fun onReceive(context: Context, intent: android.content.Intent) {
        super.onReceive(context, intent)
        if (AppWidgetManager.ACTION_APPWIDGET_UPDATE == intent.action) {
            PangbaoWidgetRenderer.updateAll(
                context, PangbaoWidgetSmallProvider::class.java, R.layout.widget_pangbao_small,
            )
        }
    }
}

class PangbaoWidgetMediumProvider : AppWidgetProvider() {
    override fun onEnabled(context: Context) {
        PangbaoWidgetRenderer.updateAll(
            context, PangbaoWidgetMediumProvider::class.java, R.layout.widget_pangbao_medium,
        )
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            PangbaoWidgetRenderer.updateAppWidget(
                context, appWidgetManager, id, R.layout.widget_pangbao_medium,
            )
        }
    }

    override fun onReceive(context: Context, intent: android.content.Intent) {
        super.onReceive(context, intent)
        if (AppWidgetManager.ACTION_APPWIDGET_UPDATE == intent.action) {
            PangbaoWidgetRenderer.updateAll(
                context, PangbaoWidgetMediumProvider::class.java, R.layout.widget_pangbao_medium,
            )
        }
    }
}

class PangbaoWidgetLargeProvider : AppWidgetProvider() {
    override fun onEnabled(context: Context) {
        PangbaoWidgetRenderer.updateAll(
            context, PangbaoWidgetLargeProvider::class.java, R.layout.widget_pangbao_large,
        )
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) {
            PangbaoWidgetRenderer.updateAppWidget(
                context, appWidgetManager, id, R.layout.widget_pangbao_large,
            )
        }
    }

    override fun onReceive(context: Context, intent: android.content.Intent) {
        super.onReceive(context, intent)
        if (AppWidgetManager.ACTION_APPWIDGET_UPDATE == intent.action) {
            PangbaoWidgetRenderer.updateAll(
                context, PangbaoWidgetLargeProvider::class.java, R.layout.widget_pangbao_large,
            )
        }
    }
}
