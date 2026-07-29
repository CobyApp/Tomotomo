package com.dime.tomotomo

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent

// Must match HomeWidget plugin SharedPreferences name.
private const val HOME_WIDGET_PREFS = "HomeWidgetPreferences"

class NotebookWidgetActionReceiver : BroadcastReceiver() {

  override fun onReceive(context: Context, intent: Intent?) {
    if (intent?.action != ACTION_LANG_CYCLE) return
    val store = context.getSharedPreferences(HOME_WIDGET_PREFS, Context.MODE_PRIVATE)

    // The app pushes the cycle order, so this receiver never needs to know which
    // languages exist — it used to hardcode a KO/JA pair.
    val order =
        (store.getString("notebook_widget_langs", null) ?: "")
            .split(',')
            .map { it.trim() }
            .filter { it.isNotEmpty() }
    if (order.size < 2) return

    val current = store.getString("notebook_widget_lang", null)
    val next = order[(order.indexOf(current).coerceAtLeast(0) + 1) % order.size]
    store.edit().putString("notebook_widget_lang", next).commit()

    val mgr = AppWidgetManager.getInstance(context)
    val cn = ComponentName(context, NotebookWidgetProvider::class.java)
    val ids = mgr.getAppWidgetIds(cn)
    val update =
        Intent(context, NotebookWidgetProvider::class.java).apply {
          this.action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
          putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
    context.sendBroadcast(update)
  }

  companion object {
    const val ACTION_LANG_CYCLE = "com.dime.tomotomo.action.NOTEBOOK_WIDGET_LANG_CYCLE"
  }
}
