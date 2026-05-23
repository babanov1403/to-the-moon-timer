/// Discriminated result returned by the duration picker sheet.
class DurationPickerResult {
  const DurationPickerResult.durations({
    required this.focusMinutes,
    required this.breakMinutes,
  })  : isDebug = false,
        isReset = false;

  const DurationPickerResult.debug()
      : focusMinutes = 0,
        breakMinutes = 0,
        isDebug = true,
        isReset = false;

  const DurationPickerResult.reset()
      : focusMinutes = 0,
        breakMinutes = 0,
        isDebug = false,
        isReset = true;

  final int focusMinutes;
  final int breakMinutes;
  final bool isDebug;
  final bool isReset;
}
