/// Duration options: every minute from 10 to 90 inclusive.
const List<int> kDurationMinutes = [
  10,
  11,
  12,
  13,
  14,
  15,
  16,
  17,
  18,
  19,
  20,
  21,
  22,
  23,
  24,
  25,
  26,
  27,
  28,
  29,
  30,
  31,
  32,
  33,
  34,
  35,
  36,
  37,
  38,
  39,
  40,
  41,
  42,
  43,
  44,
  45,
  46,
  47,
  48,
  49,
  50,
  51,
  52,
  53,
  54,
  55,
  56,
  57,
  58,
  59,
  60,
  61,
  62,
  63,
  64,
  65,
  66,
  67,
  68,
  69,
  70,
  71,
  72,
  73,
  74,
  75,
  76,
  77,
  78,
  79,
  80,
  81,
  82,
  83,
  84,
  85,
  86,
  87,
  88,
  89,
  90,
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
