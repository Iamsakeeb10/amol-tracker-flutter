package com.shakib.amol.amol_tracker_app

import android.content.SharedPreferences

internal object WidgetPrefsUtils {
    fun getInt(prefs: SharedPreferences, key: String, default: Int): Int {
        return when (val value = prefs.all[key]) {
            is Int -> value
            is Long -> value.toInt()
            is String -> value.toIntOrNull() ?: default
            else -> default
        }
    }

    fun getBoolean(prefs: SharedPreferences, key: String, default: Boolean): Boolean {
        return when (val value = prefs.all[key]) {
            is Boolean -> value
            is String -> value.equals("true", ignoreCase = true)
            else -> default
        }
    }

    fun getString(prefs: SharedPreferences, key: String, default: String): String {
        return when (val value = prefs.all[key]) {
            is String -> value
            else -> default
        }
    }
}
