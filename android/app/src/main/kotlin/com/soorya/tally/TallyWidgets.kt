package com.soorya.tally

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences

/** Shared plumbing for Tally's home screen widgets. */
object TallyWidgets {
    const val EXTRA_ACTION = "tally_action"
    private const val PREFS = "tally_widget"

    fun prefs(context: Context): SharedPreferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** Stores the numbers Flutter sent and redraws every Tally widget on the home screen. */
    fun save(context: Context, data: Map<String, String>) {
        prefs(context).edit().apply {
            for ((k, v) in data) putString(k, v)
            apply()
        }
        val mgr = AppWidgetManager.getInstance(context)
        for (info in mgr.installedProviders) {
            if (info.provider.packageName != context.packageName) continue
            val ids = mgr.getAppWidgetIds(info.provider)
            if (ids.isEmpty()) continue
            context.sendBroadcast(Intent(AppWidgetManager.ACTION_APPWIDGET_UPDATE).apply {
                component = info.provider
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
            })
        }
    }

    /** Opens Tally, optionally straight into an action such as "add:out". */
    fun open(context: Context, action: String? = null, request: Int = 0): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            if (action != null) putExtra(EXTRA_ACTION, action)
        }
        return PendingIntent.getActivity(context, request, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    }

    fun component(context: Context, cls: Class<*>) = ComponentName(context, cls)
}
