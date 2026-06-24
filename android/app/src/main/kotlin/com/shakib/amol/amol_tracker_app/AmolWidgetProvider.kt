package com.shakib.amol.amol_tracker_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class AmolWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (appWidgetId in appWidgetIds) {
            try {
                updateWidget(context, appWidgetManager, appWidgetId, widgetData)
            } catch (e: Exception) {
                Log.e(TAG, "Failed to update widget $appWidgetId", e)
            }
        }
    }

    companion object {
        private const val TAG = "AmolWidgetProvider"
        private const val WIDGET_TAP_REQUEST_CODE = 42

        private fun widgetTapPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                action = HomeWidgetLaunchIntent.HOME_WIDGET_LAUNCH_ACTION
                data = Uri.parse("amol://widget/home")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            var flags = PendingIntent.FLAG_UPDATE_CURRENT
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                flags = flags or PendingIntent.FLAG_IMMUTABLE
            }
            return PendingIntent.getActivity(
                context,
                WIDGET_TAP_REQUEST_CODE,
                intent,
                flags,
            )
        }

        fun updateWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            widgetData: SharedPreferences,
        ) {
            val views = RemoteViews(context.packageName, R.layout.amol_widget)

            // ── Read stored values ──────────────────────────────────────────
            val completedCount = WidgetPrefsUtils.getInt(widgetData, "completedCount", 0)
            val totalCount     = WidgetPrefsUtils.getInt(widgetData, "totalCount", 9)
            val streak         = WidgetPrefsUtils.getInt(widgetData, "currentStreak", 0)
            val hijriDateDisplay = WidgetPrefsUtils.getString(
                widgetData,
                "hijriDateDisplay",
                "",
            )

            // ── Hijri date (header right) ────────────────────────────────────
            if (hijriDateDisplay.isNotEmpty()) {
                views.setTextViewText(R.id.widget_hijri_date, hijriDateDisplay)
            }

            // ── Circular progress (0–10000 scale) ───────────────────────────
            val progressValue = if (totalCount > 0) {
                ((completedCount.toFloat() / totalCount) * 10000).toInt().coerceIn(0, 10000)
            } else {
                0
            }
            try {
                views.setProgressBar(R.id.widget_circular_progress, 10000, progressValue, false)
            } catch (e: Exception) {
                Log.w(TAG, "setProgressBar failed: ${e.message}")
            }

            // ── Center count text ────────────────────────────────────────────
            views.setTextViewText(
                R.id.widget_count_completed,
                WidgetUiUtils.toBengali(completedCount),
            )
            views.setTextViewText(
                R.id.widget_count_total,
                WidgetUiUtils.toBengali(totalCount),
            )

            // ── Streak badge (header left) ────────────────────────────────────
            views.setTextViewText(
                R.id.widget_streak_value,
                WidgetUiUtils.toBengali(streak),
            )

            // ── Tap to open app ──────────────────────────────────────────────
            val pendingIntent = widgetTapPendingIntent(context)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
