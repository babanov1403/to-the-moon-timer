/// Focus duration options: every 5 minutes from 10 to 90.
const List<int> kDurationMinutes = [
  10,
  15,
  20,
  25,
  30,
  35,
  40,
  45,
  50,
  55,
  60,
  65,
  70,
  75,
  80,
  85,
  90,
];

/// Break duration options: every 5 minutes from 5 to 20.
const List<int> kBreakDurationMinutes = [
  5,
  10,
  15,
  20,
];

/// Default session length in minutes.
const int kDefaultMinutes = 25;

/// Default break length in minutes.
const int kDefaultBreakMinutes = 5;

/// Number of completed focus sessions in one Pomodoro set.
const int kPomodoroSessionsPerSet = 4;

/// Duration of the small set-completion celebration animation.
const Duration kPomodoroSetCelebrationDuration = Duration(milliseconds: 1400);

/// Debug-only quick-test duration in seconds.
const int kDebugSeconds = 10;

/// Debug-only quick-test break duration in seconds.
const int kDebugBreakSeconds = 5;
