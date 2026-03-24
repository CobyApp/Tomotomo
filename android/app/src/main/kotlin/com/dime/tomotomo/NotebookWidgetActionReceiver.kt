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
    val action = intent?.action ?: return
    val prefs = context.getSharedPreferences(HOME_WIDGET_PREFS, Context.MODE_PRIVATE).edit()
    when (action) {
      ACTION_LANG_KO -> prefs.putString("notebook_widget_lang", "ko")
      ACTION_LANG_JA -> prefs.putString("notebook_widget_lang", "ja")
      else -> return
    }
    prefs.commit()

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
    const val ACTION_LANG_KO = "com.dime.tomotomo.action.NOTEBOOK_WIDGET_LANG_KO"
    const val ACTION_LANG_JA = "com.dime.tomotomo.action.NOTEBOOK_WIDGET_LANG_JA"
  }
}
