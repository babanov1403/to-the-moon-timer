import 'dart:convert';

/// Persisted focus-time statistics for the timer.
class TimerStatistics {
  const TimerStatistics({
    required this.totalFocusSeconds,
    required this.focusSecondsByDay,
  });

  factory TimerStatistics.empty() => const TimerStatistics(
        totalFocusSeconds: 0,
        focusSecondsByDay: {},
      );

  factory TimerStatistics.fromJsonString({
    required int totalFocusSeconds,
    required String? dailyFocusSecondsJson,
  }) {
    if (dailyFocusSecondsJson == null || dailyFocusSecondsJson.isEmpty) {
      return TimerStatistics(
        totalFocusSeconds: totalFocusSeconds,
        focusSecondsByDay: const {},
      );
    }

    final decoded = jsonDecode(dailyFocusSecondsJson);
    if (decoded is! Map<String, dynamic>) {
      return TimerStatistics(
        totalFocusSeconds: totalFocusSeconds,
        focusSecondsByDay: const {},
      );
    }

    final dailyTotals = <String, int>{};
    for (final entry in decoded.entries) {
      final value = entry.value;
      if (value is int && value > 0) {
        dailyTotals[entry.key] = value;
      } else if (value is num && value > 0) {
        dailyTotals[entry.key] = value.toInt();
      }
    }

    return TimerStatistics(
      totalFocusSeconds: totalFocusSeconds,
      focusSecondsByDay: Map.unmodifiable(dailyTotals),
    );
  }

  final int totalFocusSeconds;
  final Map<String, int> focusSecondsByDay;

  int get activeDayCount => focusSecondsByDay.values.where((v) => v > 0).length;

  int get averageFocusSecondsPerActiveDay {
    final days = activeDayCount;
    if (days == 0) return 0;
    return totalFocusSeconds ~/ days;
  }

  int todayFocusSeconds(DateTime now) => focusSecondsByDay[_dayKey(now)] ?? 0;

  String get dailyFocusSecondsJson => jsonEncode(focusSecondsByDay);

  TimerStatistics addFocusSeconds(int seconds, DateTime now) {
    if (seconds <= 0) return this;

    final key = _dayKey(now);
    final nextDailyTotals = Map<String, int>.from(focusSecondsByDay);
    nextDailyTotals[key] = (nextDailyTotals[key] ?? 0) + seconds;

    return TimerStatistics(
      totalFocusSeconds: totalFocusSeconds + seconds,
      focusSecondsByDay: Map.unmodifiable(nextDailyTotals),
    );
  }

  static String _dayKey(DateTime dateTime) {
    final local = dateTime.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
