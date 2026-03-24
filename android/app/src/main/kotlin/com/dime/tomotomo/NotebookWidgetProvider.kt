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

    val payloadKo = widgetData.getString("notebook_widget_payload_ko", null)
    val payloadJa = widgetData.getString("notebook_widget_payload_ja", null)
    val loggedOut = payloadKo == null && payloadJa == null

    val lang = widgetData.getString("notebook_widget_lang", "ko") ?: "ko"
    val payloadKey =
        if (lang == "ja") "notebook_widget_payload_ja" else "notebook_widget_payload_ko"
    val raw = widgetData.getString(payloadKey, null) ?: "[]"
    val lines = parsePayload(raw).take(5)

    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.notebook_widget).apply {
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

            if (loggedOut) {
              setViewVisibility(R.id.widget_empty, View.VISIBLE)
              setTextViewText(R.id.widget_empty, context.getString(R.string.widget_login_hint))
              lineIds.forEach { setViewVisibility(it, View.GONE) }
            } else if (lines.isEmpty()) {
              setViewVisibility(R.id.widget_empty, View.VISIBLE)
              setTextViewText(
                  R.id.widget_empty,
                  context.getString(R.string.widget_notebook_empty_hint),
              )
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
