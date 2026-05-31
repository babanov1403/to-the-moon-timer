/// Android notification channel and phrase constants for active timers.
abstract final class TimerNotificationConfig {
  static const int notificationId = 1001;

  static const String channelId = 'timer_countdown';
  static const String channelName = 'Timer countdown';
  static const String channelDescription =
      'Shows countdown while the To The Moon Timer is active.';

  static const String appTitle = 'To The Moon Timer';
  static const String activePhrase = 'Sailing through the galaxy... 🚀';
  static const String focusCompletePhrase = 'Focus complete! 🌕';
  static const String restCompletePhrase = 'Rest complete! ⭐';
  static const String timerCompletePhrase = 'Timer complete! 🪐';
}
