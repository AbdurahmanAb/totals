import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:workmanager/workmanager.dart';
import 'package:totals/background/daily_spending_worker.dart';

class WidgetRefreshScheduler {
  WidgetRefreshScheduler._();

  static const Duration _refreshFrequency = Duration(hours: 24);

  static Future<void> syncWidgetRefreshSchedule() async {
    if (kIsWeb) return;

    try {
      await Workmanager().registerPeriodicTask(
        widgetMidnightRefreshUniqueName,
        widgetMidnightRefreshTask,
        existingWorkPolicy: ExistingWorkPolicy.replace,
        frequency: _refreshFrequency,
        initialDelay: initialDelayUntil(const TimeOfDay(hour: 0, minute: 0)),
      );
    } catch (e) {
      if (kDebugMode) {
        print('debug: Failed to sync widget refresh schedule: $e');
      }
    }
  }
}
