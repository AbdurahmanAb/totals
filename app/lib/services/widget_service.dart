import 'dart:convert';

import 'package:home_widget/home_widget.dart';
import 'package:totals/services/widget_data_provider.dart';

class WidgetService {
  static const String appGroupId = 'group.com.example.totals.widget';
  static const String androidWidgetName = 'ExpenseWidgetProvider';

  static WidgetDataProvider? _dataProvider;

  static WidgetDataProvider get dataProvider {
    _dataProvider ??= WidgetDataProvider();
    return _dataProvider!;
  }

  /// Initialize the widget plugin
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
  }

  /// Refresh widget with current data
  static Future<void> refreshWidget() async {
    try {
      final todaySpending = await dataProvider.getTodaySpending();
      final formattedAmount = dataProvider.formatAmountForWidget(todaySpending);
      final lastUpdated = dataProvider.getLastUpdatedTimestamp();
      final categories = await dataProvider.getTodayCategoryBreakdown();

      await HomeWidget.saveWidgetData<String>('expense_total', formattedAmount);
      await HomeWidget.saveWidgetData<String>(
          'expense_total_raw', todaySpending.toString());
      await HomeWidget.saveWidgetData<String>(
          'expense_last_updated', lastUpdated);

      final categoryJson =
          jsonEncode(categories.map((c) => c.toJson()).toList());
      await HomeWidget.saveWidgetData<String>(
          'expense_categories', categoryJson);

      for (int i = 0; i < 3; i++) {
        if (i < categories.length) {
          final cat = categories[i];
          await HomeWidget.saveWidgetData<String>(
              'category_${i}_name', cat.name);
          await HomeWidget.saveWidgetData<String>(
              'category_${i}_amount',
              dataProvider.formatAmountForWidget(cat.amount));
          await HomeWidget.saveWidgetData<String>(
              'category_${i}_amount_raw', cat.amount.toString());
          await HomeWidget.saveWidgetData<String>(
              'category_${i}_color', cat.colorHex);
        } else {
          await HomeWidget.saveWidgetData<String>('category_${i}_name', '');
          await HomeWidget.saveWidgetData<String>('category_${i}_amount', '');
          await HomeWidget.saveWidgetData<String>('category_${i}_amount_raw', '0');
          await HomeWidget.saveWidgetData<String>('category_${i}_color', '');
        }
      }
      await HomeWidget.updateWidget(androidName: androidWidgetName);

      print('Widget updated: $formattedAmount at $lastUpdated');
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  /// Send basic data to the widget
  static Future<void> updateWidgetData({
    required String totalAmount,
    required String lastUpdated,
  }) async {
    await HomeWidget.saveWidgetData<String>('expense_total', totalAmount);
    await HomeWidget.saveWidgetData<String>('expense_last_updated', lastUpdated);
    await HomeWidget.updateWidget(
      androidName: androidWidgetName,
    );
  }
}
