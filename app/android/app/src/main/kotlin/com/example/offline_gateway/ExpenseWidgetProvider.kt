package com.example.offline_gateway

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Locale
import kotlin.math.roundToInt

class ExpenseWidgetProvider : HomeWidgetProvider() {
    companion object {
        private const val ACTION_TOGGLE_VISIBILITY =
            "com.example.offline_gateway.widget.TOGGLE_VISIBILITY"
        private const val PREF_KEY_HIDDEN_PREFIX = "expense_widget_hidden_"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == ACTION_TOGGLE_VISIBILITY) {
            val widgetId = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
            if (widgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return

            val prefs = HomeWidgetPlugin.getData(context)
            val key = "$PREF_KEY_HIDDEN_PREFIX$widgetId"
            val newState = !prefs.getBoolean(key, false)
            prefs.edit().putBoolean(key, newState).apply()

            val appWidgetManager = AppWidgetManager.getInstance(context)
            onUpdate(context, appWidgetManager, intArrayOf(widgetId), prefs)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_expense_layout)
            val hiddenKey = "$PREF_KEY_HIDDEN_PREFIX$widgetId"
            val isHidden = widgetData.getBoolean(hiddenKey, false)

            val toggleIntent = Intent(context, ExpenseWidgetProvider::class.java).apply {
                action = ACTION_TOGGLE_VISIBILITY
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            }
            val toggleFlags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            } else {
                PendingIntent.FLAG_UPDATE_CURRENT
            }
            val togglePendingIntent = PendingIntent.getBroadcast(
                context,
                widgetId,
                toggleIntent,
                toggleFlags
            )
            views.setOnClickPendingIntent(R.id.toggle_visibility, togglePendingIntent)
            views.setImageViewResource(
                R.id.toggle_visibility,
                if (isHidden) R.drawable.ic_visibility_off else R.drawable.ic_visibility_on
            )

            val totalAmount = widgetData.getString("expense_total", "0 ETB") ?: "0 ETB"
            val lastUpdated = widgetData.getString("expense_last_updated", "--") ?: "--"

            val parts = totalAmount.trim().split(" ")
            val value = parts.getOrNull(0) ?: "0"
            val currency = parts.getOrNull(1) ?: "ETB"

            views.setTextViewText(R.id.last_updated, lastUpdated)

            val categoryRowIds = listOf(
                R.id.category_row_0,
                R.id.category_row_1,
                R.id.category_row_2
            )
            val categoryNameIds = listOf(
                R.id.category_name_0,
                R.id.category_name_1,
                R.id.category_name_2
            )
            val categoryAmountIds = listOf(
                R.id.category_amount_0,
                R.id.category_amount_1,
                R.id.category_amount_2
            )
            val categoryDotIds = listOf(
                R.id.category_dot_0,
                R.id.category_dot_1,
                R.id.category_dot_2
            )

            val rankColors = intArrayOf(
                Color.parseColor("#5AC8FA"),
                Color.parseColor("#FFB347"),
                Color.parseColor("#FF5D73")
            )

            if (isHidden) {
                views.setTextViewText(R.id.expense_total_value, "***")
                views.setTextViewText(R.id.expense_total_currency, "")
                views.setViewVisibility(R.id.category_bar, View.VISIBLE)

                val barBitmap = createCategoryBarBitmap(
                    context = context,
                    appWidgetManager = appWidgetManager,
                    widgetId = widgetId,
                    widgetData = widgetData,
                    colors = rankColors
                )
                if (barBitmap != null) {
                    views.setImageViewBitmap(R.id.category_bar, barBitmap)
                }

                val totalRaw = widgetData.getString("expense_total_raw", null)
                    ?.toDoubleOrNull()
                    ?: parseCompactAmount(widgetData.getString("expense_total", null))
                val amounts = DoubleArray(3) { index ->
                    widgetData.getString("category_${index}_amount_raw", null)
                        ?.toDoubleOrNull()
                        ?.takeIf { it > 0.0 }
                        ?: parseCompactAmount(widgetData.getString("category_${index}_amount", null))
                }
                val sumTop = amounts.sum()
                var base = if (totalRaw > 0.0) totalRaw else sumTop
                if (base < sumTop) base = sumTop

                for (i in 0..2) {
                    val name = widgetData.getString("category_${i}_name", "") ?: ""
                    if (name.isNotEmpty()) {
                        val percent = if (base > 0.0) {
                            ((amounts[i] / base) * 100).roundToInt()
                        } else {
                            0
                        }
                        views.setViewVisibility(categoryRowIds[i], View.VISIBLE)
                        views.setTextViewText(categoryNameIds[i], name)
                        views.setTextViewText(categoryAmountIds[i], "$percent%")
                        views.setInt(categoryDotIds[i], "setColorFilter", rankColors[i])
                    } else {
                        views.setViewVisibility(categoryRowIds[i], View.GONE)
                    }
                }
            } else {
                views.setTextViewText(R.id.expense_total_value, value)
                views.setTextViewText(R.id.expense_total_currency, " $currency")
                views.setViewVisibility(R.id.category_bar, View.VISIBLE)

                val barBitmap = createCategoryBarBitmap(
                    context = context,
                    appWidgetManager = appWidgetManager,
                    widgetId = widgetId,
                    widgetData = widgetData,
                    colors = rankColors
                )
                if (barBitmap != null) {
                    views.setImageViewBitmap(R.id.category_bar, barBitmap)
                }

                for (i in 0..2) {
                    val name = widgetData.getString("category_${i}_name", "") ?: ""
                    val amount = widgetData.getString("category_${i}_amount", "") ?: ""

                    if (name.isNotEmpty()) {
                        views.setViewVisibility(categoryRowIds[i], View.VISIBLE)
                        views.setTextViewText(categoryNameIds[i], name)
                        views.setTextViewText(categoryAmountIds[i], amount)
                        views.setInt(categoryDotIds[i], "setColorFilter", rankColors[i])
                    } else {
                        views.setViewVisibility(categoryRowIds[i], View.GONE)
                    }
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun createCategoryBarBitmap(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
        widgetData: SharedPreferences,
        colors: IntArray
    ): Bitmap? {
        val options = appWidgetManager.getAppWidgetOptions(widgetId)
        val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
            .takeIf { it > 0 }
            ?: options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_WIDTH)
        val density = context.resources.displayMetrics.density
        val widthPx = (widthDp * density).toInt().coerceAtLeast(1)
        val heightPx = (10 * density).toInt().coerceAtLeast(1)

        val totalRaw = widgetData.getString("expense_total_raw", null)
            ?.toDoubleOrNull()
            ?: parseCompactAmount(widgetData.getString("expense_total", null))
        val amounts = DoubleArray(3) { index ->
            widgetData.getString("category_${index}_amount_raw", null)
                ?.toDoubleOrNull()
                ?.takeIf { it > 0.0 }
                ?: parseCompactAmount(widgetData.getString("category_${index}_amount", null))
        }

        val sumTop = amounts.sum()
        var base = if (totalRaw > 0.0) totalRaw else sumTop
        if (base < sumTop) base = sumTop
        if (base <= 0.0) return null

        val bitmap = Bitmap.createBitmap(widthPx, heightPx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        val radius = heightPx / 2f
        val clipPath = Path().apply {
            addRoundRect(
                RectF(0f, 0f, widthPx.toFloat(), heightPx.toFloat()),
                radius,
                radius,
                Path.Direction.CW
            )
        }
        canvas.clipPath(clipPath)

        var startX = 0f
        for (i in 0..2) {
            val fraction = amounts[i] / base
            val segmentWidth = (fraction * widthPx).toFloat()
            if (segmentWidth <= 0f) continue
            paint.color = colors[i]
            val endX = (startX + segmentWidth).coerceAtMost(widthPx.toFloat())
            canvas.drawRect(startX, 0f, endX, heightPx.toFloat(), paint)
            startX = endX
        }

        return bitmap
    }

    private fun parseCompactAmount(raw: String?): Double {
        if (raw.isNullOrBlank()) return 0.0
        val normalized = raw.trim().lowercase(Locale.US).replace("etb", "").trim()
        if (normalized.isEmpty()) return 0.0
        val multiplier = when {
            normalized.endsWith("k") -> 1000.0
            normalized.endsWith("m") -> 1000000.0
            else -> 1.0
        }
        val numeric = normalized.trimEnd('k', 'm').replace(",", "").trim()
        return numeric.toDoubleOrNull()?.times(multiplier) ?: 0.0
    }
}
