package com.example.offline_gateway

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
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
            val totalAmount = widgetData.getString("expense_total", "0") ?: "0"
            val lastUpdated = widgetData.getString("expense_last_updated", "--") ?: "--"

            // Set the total amount text
            views.setTextViewText(R.id.expense_total, totalAmount)
            views.setTextViewText(R.id.last_updated, lastUpdated)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
