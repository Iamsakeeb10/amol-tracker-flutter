package com.shakib.amol.amol_tracker_app

import android.content.SharedPreferences

internal enum class AmalFieldStatus { DONE, MISSED, PENDING }

internal object WidgetUiUtils {
    private val bnDigits = charArrayOf('০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯')

    fun toBengali(number: Int): String {
        if (number == 0) return "০"
        return number.toString().map { bnDigits[it - '0'] }.joinToString("")
    }

    fun scoreLabel(score: Int): String = when {
        score <= 0 -> "আজ শুরু করো"
        score < 40 -> "চেষ্টা চালিয়ে যাও"
        score < 60 -> "মোটামুটি ভালো"
        score < 80 -> "ভালো করছো!"
        score < 100 -> "চমৎকার!"
        else -> "মাশাআল্লাহ"
    }

    fun remainingAmalText(remaining: Int): String {
        if (remaining <= 0) return "সব আমল সম্পন্ন!"
        return "আর ${toBengali(remaining)}টি বাকি"
    }

    fun fieldNumericValue(widgetData: SharedPreferences, fieldId: String): Int {
        val raw = WidgetPrefsUtils.getString(widgetData, "amal_$fieldId", "0")
        return raw.toIntOrNull()?.coerceAtLeast(0) ?: 0
    }

    fun fieldStatus(
        widgetData: SharedPreferences,
        fieldId: String,
        isSubmitted: Boolean,
    ): AmalFieldStatus {
        val raw = WidgetPrefsUtils.getString(widgetData, "amal_$fieldId", "")
        val done = when {
            raw.equals("true", ignoreCase = true) -> true
            raw.toIntOrNull()?.let { it > 0 } == true -> true
            else -> false
        }
        return when {
            done -> AmalFieldStatus.DONE
            isSubmitted -> AmalFieldStatus.MISSED
            else -> AmalFieldStatus.PENDING
        }
    }

    fun statusIconRes(status: AmalFieldStatus): Int = when (status) {
        AmalFieldStatus.DONE -> R.drawable.widget_ic_check
        AmalFieldStatus.MISSED -> R.drawable.widget_ic_close
        AmalFieldStatus.PENDING -> R.drawable.widget_ic_pending
    }

    fun streakLine(streak: Int): String {
        if (streak <= 0) return ""
        return "${toBengali(streak)} দিনের ধারা"
    }
}
