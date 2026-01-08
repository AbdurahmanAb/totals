package com.example.offline_gateway

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class ExpenseWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_expense_layout)

            // Read data from SharedPreferences (set by Flutter)
            val totalAmount = widgetData.getString("expense_total", "0 ETB") ?: "0 ETB"
            val lastUpdated = widgetData.getString("expense_last_updated", "--") ?: "--"

            val parts = totalAmount.trim().split(" ")
            val value = parts.getOrNull(0) ?: "0"
            val currency = parts.getOrNull(1) ?: "ETB"

            views.setTextViewText(R.id.expense_total_value, value)
            views.setTextViewText(R.id.expense_total_currency, " $currency")
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
            val categoryBarIds = listOf(
                R.id.category_bar_0,
                R.id.category_bar_1,
                R.id.category_bar_2
            )

            for (i in 0..2) {
                val name = widgetData.getString("category_${i}_name", "") ?: ""
                val amount = widgetData.getString("category_${i}_amount", "") ?: ""
                val colorHex =
                    widgetData.getString("category_${i}_color", "#9E9E9E") ?: "#9E9E9E"

                if (name.isNotEmpty()) {
                    views.setViewVisibility(categoryRowIds[i], View.VISIBLE)
                    views.setTextViewText(categoryNameIds[i], name)
                    views.setTextViewText(categoryAmountIds[i], amount)

                    try {
                        val color = Color.parseColor(colorHex)
                        views.setInt(categoryDotIds[i], "setColorFilter", color)
                        views.setInt(categoryBarIds[i], "setBackgroundColor", color)
                    } catch (e: Exception) {
                        views.setInt(categoryDotIds[i], "setColorFilter", Color.GRAY)
                        views.setInt(categoryBarIds[i], "setBackgroundColor", Color.GRAY)
                    }
                } else {
                    views.setViewVisibility(categoryRowIds[i], View.GONE)
                    views.setInt(categoryDotIds[i], "setColorFilter", Color.TRANSPARENT)
                    views.setInt(categoryBarIds[i], "setBackgroundColor", Color.TRANSPARENT)
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
