package com.dime.tomotomo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray

class NotebookWidgetProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val lineIds =
        intArrayOf(
            R.id.widget_line_1,
            R.id.widget_line_2,
            R.id.widget_line_3,
            R.id.widget_line_4,
            R.id.widget_line_5,
        )

    val lang = widgetData.getString("notebook_widget_lang", "ko") ?: "ko"
    // One payload slot per language. Hardcoding ko/ja showed the Korean list to
    // English and Chinese learners instead of their own saved words.
    val raw = widgetData.getString("notebook_widget_payload_$lang", null) ?: "[]"
    val lines = parsePayload(raw).take(5)

    // Chrome text pushed by the app in the user's chosen language; the bundled
    // string resources are Japanese only, with no values-ko/-en/-zh variants.
    val title =
        widgetData.getString("notebook_widget_title", null)
            ?: context.getString(R.string.widget_notebook_title)
    val emptyText =
        widgetData.getString("notebook_widget_empty", null)
            ?: context.getString(R.string.widget_notebook_empty_hint)

    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.notebook_widget).apply {
            setTextViewText(R.id.widget_title, title)

            val koActive = lang == "ko"
            setInt(
                R.id.widget_btn_ko,
                "setBackgroundResource",
                if (koActive) R.drawable.widget_lang_active else R.drawable.widget_lang_inactive,
            )
            setInt(
                R.id.widget_btn_ja,
                "setBackgroundResource",
                if (!koActive) R.drawable.widget_lang_active else R.drawable.widget_lang_inactive,
            )

            val piKo =
                PendingIntent.getBroadcast(
                    context,
                    7101,
                    Intent(context, NotebookWidgetActionReceiver::class.java)
                        .setAction(NotebookWidgetActionReceiver.ACTION_LANG_KO),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            val piJa =
                PendingIntent.getBroadcast(
                    context,
                    7102,
                    Intent(context, NotebookWidgetActionReceiver::class.java)
                        .setAction(NotebookWidgetActionReceiver.ACTION_LANG_JA),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
            setOnClickPendingIntent(R.id.widget_btn_ko, piKo)
            setOnClickPendingIntent(R.id.widget_btn_ja, piJa)

            setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            if (lines.isEmpty()) {
              setViewVisibility(R.id.widget_empty, View.VISIBLE)
              setTextViewText(R.id.widget_empty, emptyText)
              lineIds.forEach { setViewVisibility(it, View.GONE) }
            } else {
              setViewVisibility(R.id.widget_empty, View.GONE)
              lineIds.forEachIndexed { idx, id ->
                if (idx < lines.size) {
                  setTextViewText(id, lines[idx])
                  setViewVisibility(id, View.VISIBLE)
                } else {
                  setViewVisibility(id, View.GONE)
                }
              }
            }
          }
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  private fun parsePayload(json: String): List<String> {
    return try {
      val arr = JSONArray(json)
      (0 until arr.length()).map { i ->
            val o = arr.optJSONObject(i) ?: return@map ""
            val c = o.optString("c", "").trim()
            val t = o.optString("t", "").trim()
            when {
              c.isEmpty() && t.isEmpty() -> ""
              t.isEmpty() -> c
              c.isEmpty() -> t
              else -> "$c  ·  $t"
            }
          }
          .filter { it.isNotEmpty() }
    } catch (_: Exception) {
      emptyList()
    }
  }
}
