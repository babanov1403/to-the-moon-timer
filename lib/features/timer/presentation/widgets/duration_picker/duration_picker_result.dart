/// Discriminated result returned by the duration picker sheet.
class DurationPickerResult {
  const DurationPickerResult.minutes(this.minutes)
      : isDebug = false,
        isReset = false;

  const DurationPickerResult.debug()
      : minutes = 0,
        isDebug = true,
        isReset = false;

  const DurationPickerResult.reset()
      : minutes = 0,
        isDebug = false,
        isReset = true;

  final int minutes;
  final bool isDebug;
  final bool isReset;
}
