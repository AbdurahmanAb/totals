import 'package:home_widget/home_widget.dart';

class WidgetService {
  static const String appGroupId = 'group.com.example.totals.widget';
  static const String androidWidgetName = 'ExpenseWidgetProvider';

  /// Initialize the widget plugin
  static Future<void> initialize() async {
    await HomeWidget.setAppGroupId(appGroupId);
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
