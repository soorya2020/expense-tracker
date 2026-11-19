package com.soorya.tally

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews

/** The Budgets board: up to four category budgets and today's safe amount. */
class BudgetsWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray) {
        for (id in ids) draw(context, mgr, id)
    }

    override fun onAppWidgetOptionsChanged(context: Context, mgr: AppWidgetManager, id: Int, options: Bundle) {
        draw(context, mgr, id)
    }

    private fun draw(context: Context, mgr: AppWidgetManager, id: Int) {
        val p = TallyWidgets.prefs(context)
        val v = RemoteViews(context.packageName, R.layout.widget_budgets)
        val daysLeft = p.getString("daysLeft", null)
        v.setTextViewText(R.id.title, if (daysLeft == null) "BUDGETS" else "BUDGETS · $daysLeft DAYS LEFT")
        val safe = p.getString("safe", null)
        val code = p.getString("paceCode", "none")
        v.setTextViewText(R.id.safe, if (safe == null || code == "none") "" else "$safe safe today")
        v.setTextColor(R.id.safe, if (code == "bad") Color.parseColor("#FF7B7F") else if (code == "warn") Color.parseColor("#FFB547") else Color.parseColor("#2BD4B8"))

        val lines = (p.getString("budgets", "") ?: "").split(";").filter { it.isNotBlank() }
        val rows = listOf(
            Triple(R.id.row1, R.id.name1, Pair(R.id.bar1, R.id.pct1)),
            Triple(R.id.row2, R.id.name2, Pair(R.id.bar2, R.id.pct2)),
            Triple(R.id.row3, R.id.name3, Pair(R.id.bar3, R.id.pct3)),
            Triple(R.id.row4, R.id.name4, Pair(R.id.bar4, R.id.pct4)),
        )
        // Fit as many rows as the widget's height allows.
        val opts = mgr.getAppWidgetOptions(id)
        val heightDp = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 110).coerceAtLeast(110)
        val fits = ((heightDp - 32 - 16) / 26).coerceIn(1, 4)
        val widthDp = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 250).coerceAtLeast(200)
        val density = context.resources.displayMetrics.density
        val barW = ((widthDp - 32 - 78 - 46 - 8) * density).toInt().coerceAtLeast(40)
        val barH = (8 * density).toInt().coerceAtLeast(4)

        for ((i, r) in rows.withIndex()) {
            val (rowId, nameId, rest) = r
            val (barId, pctId) = rest
            if (i >= lines.size || i >= fits) {
                v.setViewVisibility(rowId, View.GONE)
                continue
            }
            val parts = lines[i].split("|")
            val name = parts.getOrElse(0) { "" }
            val pct = parts.getOrElse(1) { "0" }.toIntOrNull() ?: 0
            val state = parts.getOrElse(2) { "fine" }
            val catColor = parts.getOrElse(3) { "" }.toLongOrNull()?.toInt() ?: Color.WHITE
            val color = when (state) {
                "over" -> Color.parseColor("#E5484D")
                "near" -> Color.parseColor("#F29F05")
                else -> catColor
            }
            v.setViewVisibility(rowId, View.VISIBLE)
            v.setTextViewText(nameId, name)
            v.setTextViewText(pctId, "$pct%")
            v.setTextColor(pctId, when (state) {
                "over" -> Color.parseColor("#FF7B7F")
                "near" -> Color.parseColor("#FFB547")
                else -> Color.WHITE
            })
            v.setImageViewBitmap(barId, bar(barW, barH, pct / 100f, color))
        }
        v.setViewVisibility(R.id.empty, if (lines.isEmpty()) View.VISIBLE else View.GONE)
        v.setOnClickPendingIntent(R.id.root, TallyWidgets.open(context, "budgets", 10))
        mgr.updateAppWidget(id, v)
    }

    private fun bar(w: Int, h: Int, frac: Float, color: Int): Bitmap {
        val b = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
        val c = Canvas(b)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val r = h / 2f
        paint.color = Color.parseColor("#272C38")
        c.drawRoundRect(RectF(0f, 0f, w.toFloat(), h.toFloat()), r, r, paint)
        val f = frac.coerceIn(0f, 1f)
        if (f > 0f) {
            paint.color = color
            c.drawRoundRect(RectF(0f, 0f, (w * f).coerceAtLeast(h.toFloat()), h.toFloat()), r, r, paint)
        }
        return b
    }
}
