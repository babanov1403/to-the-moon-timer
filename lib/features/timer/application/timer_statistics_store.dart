import 'package:shared_preferences/shared_preferences.dart';

import '../domain/timer_statistics.dart';

/// Stores focus-time statistics in local persistent storage.
class TimerStatisticsStore {
  TimerStatisticsStore({SharedPreferences? preferences})
      : _preferences = preferences;

  static const String _totalFocusSecondsKey = 'timer_stats_total_focus_seconds';
  static const String _dailyFocusSecondsKey = 'timer_stats_daily_focus_seconds';

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<TimerStatistics> load() async {
    final prefs = await _prefs;
    return TimerStatistics.fromJsonString(
      totalFocusSeconds: prefs.getInt(_totalFocusSecondsKey) ?? 0,
      dailyFocusSecondsJson: prefs.getString(_dailyFocusSecondsKey),
    );
  }

  Future<TimerStatistics> addFocusSeconds(int seconds) async {
    final current = await load();
    final next = current.addFocusSeconds(seconds, DateTime.now());
    await _save(next);
    return next;
  }

  Future<TimerStatistics> reset() async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.remove(_totalFocusSecondsKey),
      prefs.remove(_dailyFocusSecondsKey),
    ]);
    return TimerStatistics.empty();
  }

  Future<void> _save(TimerStatistics statistics) async {
    final prefs = await _prefs;
    await Future.wait([
      prefs.setInt(_totalFocusSecondsKey, statistics.totalFocusSeconds),
      prefs.setString(
        _dailyFocusSecondsKey,
        statistics.dailyFocusSecondsJson,
      ),
    ]);
  }
}
