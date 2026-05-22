package com.shakib.amol.amol_tracker_app

import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

internal data class AmalFieldMeta(
    val id: String,
    val label: String,
    val isNumeric: Boolean,
    val maxValue: Int,
)

internal object WidgetAmalListBuilder {
    private const val MAX_FIELDS = 14

    fun parseMeta(json: String): List<AmalFieldMeta> {
        if (json.isBlank()) return emptyList()
        return try {
            val array = JSONArray(json)
            buildList {
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    val id = obj.optString("id", "").trim()
                    if (id.isEmpty()) continue
                    add(
                        AmalFieldMeta(
                            id = id,
                            label = obj.optString("label", id),
                            isNumeric = obj.optInt("type", 0) == 1,
                            maxValue = obj.optInt("max", 1).coerceAtLeast(1),
                        ),
                    )
                }
            }.take(MAX_FIELDS)
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun resolveFields(widgetData: SharedPreferences): List<AmalFieldMeta> {
        val fromJson = parseMeta(WidgetPrefsUtils.getString(widgetData, "amalFieldsMeta", ""))
        if (fromJson.isNotEmpty()) return fromJson

        val ids = WidgetPrefsUtils.getString(widgetData, "amalFieldIds", "")
            .split(",")
            .map { it.trim() }
            .filter { it.isNotEmpty() }
        return ids.map { id ->
            AmalFieldMeta(
                id = id,
                label = fallbackLabel(id),
                isNumeric = id == "fard" || id == "takbir",
                maxValue = if (id == "fard" || id == "takbir") 5 else 1,
            )
        }.take(MAX_FIELDS)
    }

    private fun fallbackLabel(id: String): String = when (id) {
        "fard" -> "ফরয নামাজ"
        "takbir" -> "তাকবীরে উলা"
        "morning_azkar" -> "সকালের আযকার"
        "evening_azkar" -> "সন্ধ্যার আযকার"
        "quran" -> "কুরআন"
        "mulk" -> "সূরা মূলক"
        "miswak" -> "মিসওয়াক"
        "sunnah" -> "সুন্নাহ+বিতির"
        "post_azkar" -> "নামাজের আযকার"
        else -> id
    }

    fun bindAmalColumns(
        context: Context,
        views: RemoteViews,
        widgetData: SharedPreferences,
        isSubmitted: Boolean,
    ) {
        val meta = resolveFields(widgetData)
        if (meta.isEmpty()) {
            views.setViewVisibility(R.id.widget_amal_section, View.GONE)
            return
        }

        views.setViewVisibility(R.id.widget_amal_section, View.VISIBLE)
        val splitAt = (meta.size + 1) / 2
        val col1 = meta.take(splitAt)
        val col2 = meta.drop(splitAt)

        col1.forEach { field ->
            addRow(context, views, R.id.widget_amal_col1, field, widgetData, isSubmitted)
        }
        col2.forEach { field ->
            addRow(context, views, R.id.widget_amal_col2, field, widgetData, isSubmitted)
        }
    }

    private fun addRow(
        context: Context,
        views: RemoteViews,
        columnId: Int,
        field: AmalFieldMeta,
        widgetData: SharedPreferences,
        isSubmitted: Boolean,
    ) {
        val row = RemoteViews(context.packageName, R.layout.widget_amal_row)
        row.setTextViewText(R.id.amal_row_label, field.label)

        if (field.isNumeric) {
            val value = WidgetUiUtils.fieldNumericValue(widgetData, field.id)
                .coerceIn(0, field.maxValue)
            row.setViewVisibility(R.id.amal_row_status, View.GONE)
            row.setTextViewText(
                R.id.amal_row_value,
                "${WidgetUiUtils.toBengali(value)}/${WidgetUiUtils.toBengali(field.maxValue)}",
            )
            row.setViewVisibility(R.id.amal_row_value, View.VISIBLE)
        } else {
            val status = WidgetUiUtils.fieldStatus(widgetData, field.id, isSubmitted)
            row.setImageViewResource(
                R.id.amal_row_status,
                WidgetUiUtils.statusIconRes(status),
            )
            row.setViewVisibility(R.id.amal_row_status, View.VISIBLE)
            row.setViewVisibility(R.id.amal_row_value, View.GONE)
        }

        views.addView(columnId, row)
    }
}
