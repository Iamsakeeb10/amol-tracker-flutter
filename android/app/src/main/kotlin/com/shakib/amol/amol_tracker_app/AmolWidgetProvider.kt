package com.shakib.amol.amol_tracker_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.util.Log
import android.view.View
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

            val score = WidgetPrefsUtils.getInt(widgetData, "score", 0)
            val maxScore = WidgetPrefsUtils.getInt(widgetData, "maxScore", 100)
            val completedCount = WidgetPrefsUtils.getInt(widgetData, "completedCount", 0)
            val totalCount = WidgetPrefsUtils.getInt(widgetData, "totalCount", 9)
            val isSubmitted = WidgetPrefsUtils.getBoolean(widgetData, "isSubmitted", false)
            val streak = WidgetPrefsUtils.getInt(widgetData, "currentStreak", 0)
            val hijriDateDisplay = WidgetPrefsUtils.getString(
                widgetData,
                "hijriDateDisplay",
                "আজকের তারিখ",
            )
            val scoreLabel = WidgetPrefsUtils.getString(
                widgetData,
                "scoreLabel",
                WidgetUiUtils.scoreLabel(score),
            )

            val fieldMeta = WidgetAmalListBuilder.resolveFields(widgetData)
            val hasFields = fieldMeta.isNotEmpty()

            val remaining = (totalCount - completedCount).coerceAtLeast(0)
            val progressValue = if (maxScore > 0) {
                ((score.toFloat() / maxScore) * 100).toInt().coerceIn(0, 100)
            } else {
                0
            }

            val bgRes = if (isSubmitted) {
                R.drawable.widget_background_submitted
            } else {
                R.drawable.widget_background
            }
            views.setInt(R.id.widget_root, "setBackgroundResource", bgRes)

            views.setTextViewText(R.id.widget_hijri_date, hijriDateDisplay)
            views.setTextViewText(R.id.widget_score_main, WidgetUiUtils.toBengali(score))
            views.setTextViewText(
                R.id.widget_score_denom,
                "/${WidgetUiUtils.toBengali(maxScore)}",
            )
            views.setTextViewText(R.id.widget_score_label, scoreLabel)
            views.setProgressBar(R.id.widget_progress, 100, progressValue, false)
            views.setTextViewText(
                R.id.widget_count,
                "${WidgetUiUtils.toBengali(completedCount)}/${WidgetUiUtils.toBengali(totalCount)} আমল",
            )
            views.setTextViewText(
                R.id.widget_remaining,
                WidgetUiUtils.remainingAmalText(remaining),
            )

            WidgetAmalListBuilder.bindAmalColumns(context, views, widgetData, isSubmitted)

            if (hasFields) {
                views.setViewVisibility(R.id.widget_remaining, View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_remaining, View.VISIBLE)
            }

            val pendingIntent = widgetTapPendingIntent(context)
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            views.setOnClickPendingIntent(R.id.widget_cta, pendingIntent)

            when {
                isSubmitted -> {
                    views.setViewVisibility(R.id.widget_cta, View.GONE)
                    views.setViewVisibility(R.id.widget_empty_hint, View.GONE)

                    if (hasFields) {
                        views.setViewVisibility(R.id.widget_submitted_panel, View.GONE)
                    } else {
                        views.setViewVisibility(R.id.widget_submitted_panel, View.VISIBLE)
                        views.setTextViewText(R.id.widget_submitted_title, "আলহামদুলিল্লাহ")
                        views.setTextViewText(
                            R.id.widget_submitted_score,
                            "${WidgetUiUtils.toBengali(score)}/${WidgetUiUtils.toBengali(maxScore)} — $scoreLabel",
                        )
                        val streakText = WidgetUiUtils.streakLine(streak)
                        if (streakText.isNotEmpty()) {
                            views.setTextViewText(R.id.widget_submitted_streak, streakText)
                            views.setViewVisibility(R.id.widget_submitted_streak, View.VISIBLE)
                        } else {
                            views.setViewVisibility(R.id.widget_submitted_streak, View.GONE)
                        }
                    }
                }
                completedCount > 0 -> {
                    views.setViewVisibility(R.id.widget_submitted_panel, View.GONE)
                    views.setViewVisibility(R.id.widget_empty_hint, View.GONE)
                    views.setTextViewText(R.id.widget_cta, "জমা দাও →")
                    views.setViewVisibility(R.id.widget_cta, View.VISIBLE)
                }
                else -> {
                    views.setViewVisibility(R.id.widget_submitted_panel, View.GONE)
                    views.setViewVisibility(
                        R.id.widget_empty_hint,
                        if (!hasFields) View.VISIBLE else View.GONE,
                    )
                    views.setTextViewText(R.id.widget_cta, "আমল লগ করো →")
                    views.setViewVisibility(R.id.widget_cta, View.VISIBLE)
                }
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
