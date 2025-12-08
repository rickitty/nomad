
// import 'package:flutter/material.dart';

String getLocalized(dynamic data, String locale) {
  if (data == null || data is! Map) return "";
  return data[locale] ?? data["en"] ?? data.values.first.toString();
}

bool isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime startOfWeek(DateTime d) {
  final weekday = d.weekday;
  return d.subtract(Duration(days: weekday - 1));
}

String getTaskDisplayStatus(Map<String, dynamic> task) {
  final raw = (task['status'] ?? '').toString();

  switch (raw) {
    case 'completedNaturally':
      return 'completedN';
    case 'completedForcefully':
      return 'completedF';
    case 'in_progress':
      return 'in_progress';
    default:
      return 'pending';
  }
}

int statusOrder(String displayStatus) {
  switch (displayStatus) {
    case 'pending':
      return 0;
    case 'in_progress':
      return 1;
    default:
      return 2;
  }
}
