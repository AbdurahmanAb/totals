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

      await HomeWidget.saveWidgetData<String>('expense_total', formattedAmount);
      await HomeWidget.saveWidgetData<String>(
          'expense_last_updated', lastUpdated);
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
