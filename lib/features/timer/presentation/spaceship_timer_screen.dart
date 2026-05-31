import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../application/free_timer_controller.dart';
import '../application/timer_config.dart';
import '../application/timer_controller.dart';
import '../application/timer_formatter.dart';
import '../application/timer_notification_config.dart';
import '../application/timer_session_runtime.dart';
import '../application/timer_statistics_store.dart';
import '../domain/free_timer_state.dart';
import '../domain/free_timer_status.dart';
import '../domain/timer_state.dart';
import '../domain/timer_statistics.dart';
import '../domain/timer_status.dart';
import 'widgets/duration_picker_sheet.dart';
import 'widgets/free_timer_duration_picker/free_timer_duration_picker_result.dart';
import 'widgets/free_timer_duration_picker/free_timer_duration_picker_sheet.dart';
import 'widgets/space/planet_data.dart';
import 'widgets/space/retro_timer_widgets.dart';
import 'widgets/space/ship_style.dart';
import 'widgets/space/space_palette.dart';
import 'widgets/space/space_scene_state.dart';
import 'widgets/space/space_viewport.dart';

enum AppTimerMode { pomodoroMode, timerMode }

/// Home screen: retro arcade Pomodoro timer with a spaceship visual metaphor.
class SpaceshipTimerScreen extends StatefulWidget {
  const SpaceshipTimerScreen({super.key});

  @override
  State<SpaceshipTimerScreen> createState() => _SpaceshipTimerScreenState();
}

class _SpaceshipTimerScreenState extends State<SpaceshipTimerScreen>
    with TickerProviderStateMixin {
  late final TimerController _controller;
  late final FreeTimerController _freeTimerController;
  late final TimerStatisticsStore _statisticsStore;
  late final TimerSessionRuntime _sessionRuntime;
  late final AnimationController _exhaustCtrl;
  late final AnimationController _starCtrl;
  late final AnimationController _transitionCtrl;
  late final AnimationController _flightCtrl;
  late final AnimationController _celebrationCtrl;

  Timer? _transitionAlarmTicker;
  bool _transitionAlarmActive = false;

  AppTimerMode _appMode = AppTimerMode.pomodoroMode;
  SpaceSceneState _scene = SpaceSceneState.landed;
  TimerStatus? _prevStatus;
  TimerStatistics _statistics = TimerStatistics.empty();
  Future<void> _statisticsUpdate = Future<void>.value();
  int? _lastFocusRemainingSeconds;
  int? _lastFreeTimerRemainingSeconds;
  PlanetData _planet = PlanetData.generate(42);
  int _planetSeed = 42;
  int _lastCompletedSetCount = 0;
  final List<({Color colorA, Color colorB})> _completedPlanetColors = [];

  static const Color _cyan = Color(0xFF38BFD4);
  static const Color _yellow = Color(0xFFF1D76A);
  static const Color _muted = Color(0xFF6F789C);
  static const Color _bg = Color(0xFF071126);
  static const Color _panel = Color(0xFF111D3A);
  static const Color _textLight = Color(0xFFE7E7FF);
  static const Color _timerPurple = Color(0xFF9C7BFF);
  static const Color _timerMint = Color(0xFF5CF0C8);
  static const ShipStyle _pomodoroShipStyle = ShipStyle(
    bodyColor: SpacePalette.shipBody,
    accentColor: SpacePalette.shipAccent,
    darkColor: SpacePalette.shipDark,
    exhaustHotColor: SpacePalette.exhaustOrange,
    exhaustCoreColor: SpacePalette.exhaustWhite,
    scale: 1.9,
  );
  static const ShipStyle _timerShipStyle = ShipStyle(
    bodyColor: _timerPurple,
    accentColor: _timerMint,
    darkColor: Color(0xFF3F2C8C),
    exhaustHotColor: Color(0xFFFF5FD2),
    exhaustCoreColor: Color(0xFFE9FFF9),
    scale: 1.9,
  );

  @override
  void initState() {
    super.initState();
    _controller = TimerController()..addListener(_onTimerChanged);
    _freeTimerController = FreeTimerController()
      ..addListener(_onFreeTimerChanged);
    _statisticsStore = TimerStatisticsStore();
    _sessionRuntime = TimerSessionRuntime();
    _loadStatistics();
    _exhaustCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400))
      ..repeat();
    _starCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 90))
          ..repeat();
    _transitionCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..addStatusListener(_onTransitionDone);
    _flightCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _celebrationCtrl = AnimationController(
      vsync: this,
      duration: kPomodoroSetCelebrationDuration,
    )..addStatusListener(_onCelebrationDone);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTimerChanged);
    _freeTimerController.removeListener(_onFreeTimerChanged);
    _stopTransitionAlarm();
    _sessionRuntime.stop();
    _controller.dispose();
    _freeTimerController.dispose();
    _exhaustCtrl.dispose();
    _starCtrl.dispose();
    _transitionCtrl.dispose();
    _flightCtrl.dispose();
    _celebrationCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    final statistics = await _statisticsStore.load();
    if (!mounted) return;
    setState(() => _statistics = statistics);
  }

  void _onTimerChanged() {
    final timerState = _controller.state;
    final status = timerState.status;
    final elapsedFocusSeconds =
        _elapsedFocusSeconds(timerState.remainingSeconds);
    if (elapsedFocusSeconds > 0) _recordFocusSeconds(elapsedFocusSeconds);
    if (_appMode == AppTimerMode.pomodoroMode) {
      _syncPomodoroRuntime(timerState);
      if (status != _prevStatus) {
        final previousStatus = _prevStatus;
        _handleTransition(previousStatus, status);
      }
      _syncTransitionAlarm(timerState);
    } else {
      _stopTransitionAlarm();
    }
    if (timerState.completedSetCount > _lastCompletedSetCount) {
      _lastCompletedSetCount = timerState.completedSetCount;
      _celebrationCtrl.forward(from: 0);
      _vibrateSetComplete();
    }
    _prevStatus = status;
    _lastFocusRemainingSeconds =
        status == TimerStatus.running ? timerState.remainingSeconds : null;
    setState(() {});
  }

  void _onFreeTimerChanged() {
    final state = _freeTimerController.state;
    if (_appMode == AppTimerMode.timerMode) {
      final elapsedTimerSeconds =
          _elapsedFreeTimerSeconds(state.remainingSeconds);
      if (elapsedTimerSeconds > 0) _recordFocusSeconds(elapsedTimerSeconds);
      _syncFreeTimerRuntime(state);
      _handleFreeTimerTransition(state.status);
      _lastFreeTimerRemainingSeconds =
          state.isRunning ? state.remainingSeconds : null;
    } else {
      _lastFreeTimerRemainingSeconds = null;
    }
    setState(() {});
  }

  void _syncPomodoroRuntime(TimerState state) {
    final isRest = state.isOnBreak;
    _sessionRuntime.sync(
      isPlaying: state.isActivelyPlaying,
      isComplete: state.isAwaitingAcknowledgement || state.isSetComplete,
      modeLabel: isRest ? 'Rest' : 'Focus',
      timeLabel: TimerFormatter.format(state.remainingSeconds),
      completeMessage: _pomodoroCompleteMessage(state),
    );
  }

  void _syncFreeTimerRuntime(FreeTimerState state) {
    _sessionRuntime.sync(
      isPlaying: state.isRunning,
      isComplete: state.isFinished,
      modeLabel: 'Timer',
      timeLabel: TimerFormatter.formatLong(state.remainingSeconds),
      completeMessage: TimerNotificationConfig.timerCompletePhrase,
    );
  }

  String _pomodoroCompleteMessage(TimerState state) {
    if (state.isAwaitingFocusAcknowledgement) {
      return TimerNotificationConfig.restCompletePhrase;
    }
    return TimerNotificationConfig.focusCompletePhrase;
  }

  int _elapsedFocusSeconds(int remainingSeconds) {
    if (_prevStatus != TimerStatus.running ||
        _lastFocusRemainingSeconds == null) {
      return 0;
    }
    return (_lastFocusRemainingSeconds! - remainingSeconds).clamp(0, 3600);
  }

  int _elapsedFreeTimerSeconds(int remainingSeconds) {
    if (!_freeTimerController.state.isRunning ||
        _lastFreeTimerRemainingSeconds == null) {
      return 0;
    }
    return (_lastFreeTimerRemainingSeconds! - remainingSeconds).clamp(0, 3600);
  }

  void _recordFocusSeconds(int seconds) {
    _statisticsUpdate = _statisticsUpdate
        .then((_) => _statisticsStore.addFocusSeconds(seconds))
        .then((statistics) {
      if (mounted) setState(() => _statistics = statistics);
    }).catchError((Object _) {});
  }

  void _syncTransitionAlarm(TimerState state) {
    if (state.isAwaitingAcknowledgement) {
      _startTransitionAlarm();
    } else {
      _stopTransitionAlarm();
    }
  }

  void _startTransitionAlarm() {
    if (_transitionAlarmActive) return;
    _transitionAlarmActive = true;
    _playTransitionAlarmPulse();
    _transitionAlarmTicker = Timer.periodic(
      const Duration(milliseconds: 1200),
      (_) => _playTransitionAlarmPulse(),
    );
  }

  void _stopTransitionAlarm() {
    _transitionAlarmTicker?.cancel();
    _transitionAlarmTicker = null;
    if (!_transitionAlarmActive) return;
    _transitionAlarmActive = false;
    Vibration.cancel().catchError((Object _) {});
  }

  Future<void> _playTransitionAlarmPulse() async {
    await _playContinuousVibration(
      durationMs: 850,
      fallback: _playTransitionAlarmHapticFallback,
    );
  }

  Future<void> _playSessionEndVibration() async {
    await _playContinuousVibration(
      durationMs: 400,
      fallback: _playSessionEndHapticFallback,
    );
  }

  Future<void> _vibrateSetComplete() async {
    await _playContinuousVibration(
      durationMs: 700,
      fallback: _playSetCompleteHapticFallback,
    );
  }

  Future<void> _playContinuousVibration({
    required int durationMs,
    required VoidCallback fallback,
  }) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      final hasCustomVibrations = await Vibration.hasCustomVibrationsSupport();
      if (hasVibrator && hasCustomVibrations) {
        await Vibration.vibrate(duration: durationMs, amplitude: 255);
      } else {
        fallback();
      }
    } catch (_) {
      fallback();
    }
  }

  void _playTransitionAlarmHapticFallback() {
    HapticFeedback.heavyImpact();
    Future<void>.delayed(
      const Duration(milliseconds: 220),
      HapticFeedback.heavyImpact,
    );
    Future<void>.delayed(
      const Duration(milliseconds: 440),
      HapticFeedback.mediumImpact,
    );
    Future<void>.delayed(
      const Duration(milliseconds: 660),
      HapticFeedback.heavyImpact,
    );
  }

  void _playSessionEndHapticFallback() {
    HapticFeedback.heavyImpact();
    Future<void>.delayed(
      const Duration(milliseconds: 180),
      HapticFeedback.heavyImpact,
    );
    Future<void>.delayed(
      const Duration(milliseconds: 360),
      HapticFeedback.mediumImpact,
    );
  }

  void _playSetCompleteHapticFallback() {
    HapticFeedback.heavyImpact();
    Future<void>.delayed(
      const Duration(milliseconds: 180),
      HapticFeedback.heavyImpact,
    );
    Future<void>.delayed(
      const Duration(milliseconds: 360),
      HapticFeedback.heavyImpact,
    );
    Future<void>.delayed(
      const Duration(milliseconds: 540),
      HapticFeedback.mediumImpact,
    );
  }

  Future<bool> _confirmResetStatistics(BuildContext context) async {
    HapticFeedback.lightImpact();
    return await showDialog<bool>(
          context: context,
          builder: (context) => _RetroInfoDialog(
            title: 'RESET STATS?',
            accentColor: _yellow,
            children: [
              Text(
                'This will permanently clear total flight time and every daily heatmap cell.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textLight.withValues(alpha: 0.72),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _RetroDialogButton(
                      label: 'CANCEL',
                      color: _cyan,
                      onTap: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RetroDialogButton(
                      label: 'RESET',
                      color: _yellow,
                      onTap: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _resetStatistics() async {
    HapticFeedback.mediumImpact();
    final statistics = await _statisticsStore.reset();
    if (!mounted) return;
    setState(() => _statistics = statistics);
  }

  void _handleTransition(TimerStatus? prev, TimerStatus next) {
    final flying = _scene == SpaceSceneState.flying;
    final takingOff = _scene == SpaceSceneState.takingOff;
    if (next == TimerStatus.running && prev == TimerStatus.paused) {
      _resumeVisuals();
    } else if (next == TimerStatus.running && !flying && !takingOff) {
      _startTakeoff();
    } else if (next == TimerStatus.paused && takingOff) {
      _transitionCtrl.stop();
      _exhaustCtrl.stop();
    } else if (next == TimerStatus.paused && flying) {
      _flightCtrl.stop();
      _exhaustCtrl.stop();
      _scene = SpaceSceneState.pausedInSpace;
    } else if ((next == TimerStatus.awaitingBreakAcknowledgement ||
            next == TimerStatus.finished ||
            next == TimerStatus.setComplete) &&
        (flying || takingOff)) {
      _finishFlightAndLand();
    } else if (next == TimerStatus.setComplete) {
      _recordCurrentPlanetForCompletedFocus();
      _scene = SpaceSceneState.landed;
    } else if (_isLanded(next) &&
        !flying &&
        !takingOff &&
        _scene != SpaceSceneState.landing) {
      _scene = SpaceSceneState.landed;
    }
  }

  void _startTakeoff() {
    _scene = SpaceSceneState.takingOff;
    _exhaustCtrl.repeat();
    _transitionCtrl.forward(from: 0);
    final total = _activeCountdownSeconds;
    _flightCtrl.duration = Duration(seconds: total.clamp(1, 99999));
  }

  void _resumeVisuals() {
    _exhaustCtrl.repeat();
    if (_scene == SpaceSceneState.takingOff) {
      _transitionCtrl.forward();
    } else if (_scene == SpaceSceneState.pausedInSpace) {
      _scene = SpaceSceneState.flying;
      _flightCtrl.forward();
    }
  }

  void _finishFlightAndLand() {
    _flightCtrl.stop();
    _transitionCtrl.stop();
    _planetSeed = DateTime.now().millisecondsSinceEpoch;
    _planet = PlanetData.generate(_planetSeed);
    if (_appMode == AppTimerMode.pomodoroMode) {
      _recordCurrentPlanetForCompletedFocus();
    }
    _scene = SpaceSceneState.landing;
    _exhaustCtrl.repeat();
    _transitionCtrl.forward(from: 0);
  }

  void _recordCurrentPlanetForCompletedFocus() {
    final completed = _controller.state.completedFocusSessions;
    if (completed <= _completedPlanetColors.length ||
        _completedPlanetColors.length >= kPomodoroSessionsPerSet) {
      return;
    }
    _completedPlanetColors.add(
      (colorA: _planet.colorA, colorB: _planet.colorB),
    );
  }

  bool _isLanded(TimerStatus s) =>
      s == TimerStatus.idle ||
      s == TimerStatus.awaitingBreakAcknowledgement ||
      s == TimerStatus.breakRunning ||
      s == TimerStatus.breakPaused ||
      s == TimerStatus.breakFinished ||
      s == TimerStatus.awaitingFocusAcknowledgement ||
      s == TimerStatus.setComplete;

  void _onTransitionDone(AnimationStatus s) {
    if (s != AnimationStatus.completed) return;
    if (_scene == SpaceSceneState.takingOff) {
      _scene = SpaceSceneState.flying;
      _flightCtrl.forward(from: 0);
    } else if (_scene == SpaceSceneState.landing) {
      _scene = SpaceSceneState.landed;
    }
    setState(() {});
  }

  void _onCelebrationDone(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _celebrationCtrl.reset();
    if (mounted) setState(() {});
  }

  int get _activeCountdownSeconds {
    if (_appMode == AppTimerMode.timerMode) {
      return _freeTimerController.state.selectedSeconds;
    }
    final s = _controller.state;
    return s.isDebugMode ? kDebugSeconds : s.selectedMinutes * 60;
  }

  ShipStyle get _activeShipStyle =>
      _appMode == AppTimerMode.timerMode ? _timerShipStyle : _pomodoroShipStyle;

  bool get _isTimerMode => _appMode == AppTimerMode.timerMode;

  void _handleFreeTimerTransition(FreeTimerStatus status) {
    final flying = _scene == SpaceSceneState.flying;
    final takingOff = _scene == SpaceSceneState.takingOff;
    if (status == FreeTimerStatus.running && !flying && !takingOff) {
      _startTakeoff();
    } else if (status == FreeTimerStatus.running) {
      _resumeVisuals();
    } else if (status == FreeTimerStatus.paused && takingOff) {
      _transitionCtrl.stop();
      _exhaustCtrl.stop();
    } else if (status == FreeTimerStatus.paused && flying) {
      _flightCtrl.stop();
      _exhaustCtrl.stop();
      _scene = SpaceSceneState.pausedInSpace;
    } else if (status == FreeTimerStatus.finished && (flying || takingOff)) {
      _finishFlightAndLand();
      _playSessionEndVibration();
    } else if (status == FreeTimerStatus.idle &&
        !flying &&
        !takingOff &&
        _scene != SpaceSceneState.landing) {
      _scene = SpaceSceneState.landed;
    }
  }

  Future<void> _openPicker() async {
    if (_controller.state.isRunning) return;
    HapticFeedback.lightImpact();
    final s = _controller.state;
    final focusIdx = s.isDebugMode
        ? 0
        : kDurationMinutes
            .indexOf(s.selectedMinutes)
            .clamp(0, kDurationMinutes.length - 1);
    final breakIdx = kBreakDurationMinutes
        .indexOf(s.selectedBreakMinutes)
        .clamp(0, kBreakDurationMinutes.length - 1);
    await showDurationPickerSheet(
      context: context,
      initialFocusIndex: focusIdx,
      initialBreakIndex: breakIdx,
      onDurations: ({required focusMinutes, required breakMinutes}) {
        _controller.applyDurations(
          focusMinutes: focusMinutes,
          breakMinutes: breakMinutes,
        );
        _reset();
      },
      onDebug: () {
        _controller.applyDebugSeconds();
        _reset();
      },
      onReset: () {
        _controller.restartSet();
        _reset();
      },
    );
  }

  Future<void> _openFreeTimerPicker() async {
    if (_freeTimerController.state.isRunning) return;
    HapticFeedback.lightImpact();
    final state = _freeTimerController.state;
    final result = await showModalBottomSheet<FreeTimerDurationPickerResult>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => FreeTimerDurationPickerSheet(
        initialHours: state.selectedHours,
        initialMinutes: state.selectedMinutes,
      ),
    );

    if (result == null) return;
    _freeTimerController.applyDuration(
      hours: result.hours,
      minutes: result.minutes,
    );
    _resetVisuals(clearPomodoroProgress: false);
  }

  void _switchMode() {
    HapticFeedback.mediumImpact();
    _stopTransitionAlarm();
    if (_appMode == AppTimerMode.pomodoroMode) {
      _controller.restartSet();
      _sessionRuntime.stop();
      _resetVisuals(clearPomodoroProgress: true);
      _appMode = AppTimerMode.timerMode;
    } else {
      _freeTimerController.resetSession();
      _resetVisuals(clearPomodoroProgress: false);
      _appMode = AppTimerMode.pomodoroMode;
    }
    setState(() {});
  }

  void _reset() {
    _resetVisuals(clearPomodoroProgress: true);
    setState(() {});
  }

  void _resetVisuals({required bool clearPomodoroProgress}) {
    _stopTransitionAlarm();
    _scene = SpaceSceneState.landed;
    _prevStatus = null;
    _lastCompletedSetCount = _controller.state.completedSetCount;
    if (clearPomodoroProgress) _completedPlanetColors.clear();
    _flightCtrl.stop();
    _flightCtrl.reset();
    _transitionCtrl.stop();
    _transitionCtrl.reset();
    _celebrationCtrl.stop();
    _celebrationCtrl.reset();
    _lastFocusRemainingSeconds = null;
    _lastFreeTimerRemainingSeconds = null;
  }

  Future<void> _showStatistics() async {
    HapticFeedback.lightImpact();
    await showDialog<void>(
      context: context,
      builder: (context) => _RetroInfoDialog(
        title: 'STATISTICS',
        accentColor: _cyan,
        children: [
          _RetroStatRow(
            label: 'TOTAL FLIGHT',
            value: _formatDuration(_statistics.totalFocusSeconds),
            accentColor: _cyan,
          ),
          const SizedBox(height: 14),
          _RetroStatRow(
            label: 'AVG / ACTIVE DAY',
            value: _formatDuration(_statistics.averageFocusSecondsPerActiveDay),
            accentColor: _yellow,
          ),
          const SizedBox(height: 14),
          _RetroStatRow(
            label: 'TODAY',
            value:
                _formatDuration(_statistics.todayFocusSeconds(DateTime.now())),
            accentColor: _cyan,
          ),
          const SizedBox(height: 18),
          _RetroFlightHeatmap(
            statistics: _statistics,
            now: DateTime.now(),
            accentColor: _cyan,
            emptyColor: _muted,
            textColor: _textLight,
          ),
          const SizedBox(height: 24),
          _RetroDialogButton(
            label: 'RESET STATS',
            color: _yellow,
            onTap: () async {
              final confirmed = await _confirmResetStatistics(context);
              if (!confirmed) return;
              await _resetStatistics();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showFeedback() async {
    HapticFeedback.lightImpact();
    await showDialog<void>(
      context: context,
      builder: (context) => const _RetroInfoDialog(
        title: 'FEEDBACK',
        accentColor: _yellow,
        children: [
          Text(
            'Telegram',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
            ),
          ),
          SizedBox(height: 12),
          SelectableText(
            '@babanbrand',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _yellow,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
    }
    if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final s = _controller.state;
    final freeState = _freeTimerController.state;
    final isBreak = s.isOnBreak;
    final accent = _isTimerMode ? _timerMint : (isBreak ? _yellow : _cyan);
    final isPaused = _isTimerMode
        ? freeState.isPaused
        : s.status == TimerStatus.paused || s.status == TimerStatus.breakPaused;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _bg,
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF071126),
                Color(0xFF0B1833),
                Color(0xFF171343),
              ],
              stops: [0.0, 0.58, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -120,
                right: -90,
                child: _AtmosphereOrb(
                  color: accent.withValues(alpha: 0.12),
                  size: 260,
                ),
              ),
              Positioned(
                bottom: 90,
                left: -120,
                child: _AtmosphereOrb(
                  color: _isTimerMode
                      ? _timerPurple.withValues(alpha: 0.16)
                      : _muted.withValues(alpha: 0.18),
                  size: 300,
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(accent: accent, isBreak: isBreak),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            Expanded(
                              child: SpaceViewport(
                                state: _scene,
                                planet: _planet,
                                flightController: _flightCtrl,
                                transitionController: _transitionCtrl,
                                exhaustController: _exhaustCtrl,
                                starController: _starCtrl,
                                isPaused: isPaused,
                                shipStyle: _activeShipStyle,
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              transitionBuilder: _modeTransition,
                              child: Text(
                                _isTimerMode
                                    ? 'Any mission. Any orbit.'
                                    : 'One task. One orbit.',
                                key: ValueKey('tagline-$_appMode'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _textLight.withValues(alpha: 0.70),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 320),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: _modeTransition,
                            child: _isTimerMode
                                ? _buildTimerControls(freeState)
                                : _buildPomodoroControls(s, accent),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 52,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        transitionBuilder: _modeTransition,
                        child: _isTimerMode
                            ? _buildTimerModeSpacer()
                            : _buildPomodoroModeLabels(isBreak),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: _isTimerMode
                          ? _buildTimerPlayButton(freeState)
                          : _buildPomodoroPlayButton(s, accent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeTransition(Widget child, Animation<double> animation) {
    final curved =
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0.0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }

  Widget _buildHeader({required Color accent, required bool isBreak}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _SwitchModeButton(
              label: 'Switch',
              color: _isTimerMode ? _timerPurple : _cyan,
              onTap: _switchMode,
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: _modeTransition,
            child: RetroLabel(
              key: ValueKey('header-$_appMode-$isBreak'),
              text: _isTimerMode ? 'Timer' : (isBreak ? 'Rest' : 'Focus'),
              color: accent,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _RetroHeaderButton(
                  icon: Icons.query_stats_rounded,
                  semanticLabel: 'Statistics',
                  color: _cyan,
                  onTap: _showStatistics,
                ),
                const SizedBox(width: 10),
                _RetroHeaderButton(
                  icon: Icons.feedback_outlined,
                  semanticLabel: 'Feedback',
                  color: _yellow,
                  onTap: _showFeedback,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPomodoroControls(TimerState s, Color accent) {
    final isActive = s.isRunning || s.isBreakRunning;
    return Column(
      key: const ValueKey(AppTimerMode.pomodoroMode),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (s.isAwaitingAcknowledgement)
          _TransitionAlarmPanel(
            title: _transitionAlarmTitle(s),
            message: _transitionAlarmMessage(s),
            accentColor: accent,
            onAcknowledge: _acknowledgeTransitionAlarm,
          )
        else
          RetroTimerField(
            timeLabel: TimerFormatter.format(s.remainingSeconds),
            isRunning: isActive,
            accentColor: accent,
            onTap: _openPicker,
          ),
        const SizedBox(height: 18),
        _buildPomodoroProgress(s),
      ],
    );
  }

  Widget _buildPomodoroProgress(TimerState s) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        RetroPomodoroSetProgress(
          completedPlanetColors: _completedPlanetColors,
          completedSessions: s.completedFocusSessions,
          totalSessions: kPomodoroSessionsPerSet,
          emptyColor: _muted,
        ),
        Positioned(
          top: -54,
          right: -62,
          child: AnimatedBuilder(
            animation: _celebrationCtrl,
            builder: (context, _) {
              if (_celebrationCtrl.value == 0) {
                return const SizedBox.shrink();
              }
              return RetroFireworks(
                progress: _celebrationCtrl.value,
                primaryColor: _planet.colorA,
                secondaryColor: _yellow,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimerControls(FreeTimerState state) {
    return Column(
      key: const ValueKey(AppTimerMode.timerMode),
      mainAxisSize: MainAxisSize.min,
      children: [
        RetroTimerField(
          timeLabel: TimerFormatter.formatLong(state.remainingSeconds),
          isRunning: state.isRunning,
          accentColor: _timerMint,
          onTap: _openFreeTimerPicker,
        ),
        const SizedBox(height: 16),
        Text(
          state.isFinished
              ? 'Timer complete!'
              : state.isRunning
                  ? 'Timer mission active'
                  : 'Tap time to pick duration',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textLight.withValues(alpha: 0.58),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildPomodoroModeLabels(bool isBreak) {
    return SizedBox(
      key: const ValueKey('pomodoro-labels'),
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RetroModeLabel(
            label: 'Focus',
            active: !isBreak,
            activeColor: _cyan,
            mutedColor: _muted,
          ),
          const SizedBox(width: 32),
          RetroModeLabel(
            label: 'Rest',
            active: isBreak,
            activeColor: _yellow,
            mutedColor: _muted,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerModeSpacer() {
    return const SizedBox(
      key: ValueKey('timer-labels'),
      height: 52,
    );
  }

  Widget _buildPomodoroPlayButton(TimerState s, Color accent) {
    if (s.isAwaitingAcknowledgement) {
      return const SizedBox.shrink();
    }

    final isActive = s.isRunning || s.isBreakRunning;
    return RetroPlayButton(
      label: _playButtonLabel(s),
      isRunning: isActive,
      isFinished: s.isBreakFinished,
      isRestart: s.isSetComplete,
      accentColor: accent,
      onTap: () {
        HapticFeedback.mediumImpact();
        if (s.isSetComplete) {
          _controller.restartSet();
          _reset();
        } else {
          _controller.togglePlayPause();
        }
      },
    );
  }

  void _acknowledgeTransitionAlarm() {
    HapticFeedback.mediumImpact();
    _stopTransitionAlarm();
    _controller.acknowledgeTransitionAlarm();
  }

  Widget _buildTimerPlayButton(FreeTimerState state) {
    return RetroPlayButton(
      label: _freeTimerPlayButtonLabel(state),
      isRunning: state.isRunning,
      isFinished: false,
      isRestart: state.isFinished,
      accentColor: _timerMint,
      onTap: () {
        HapticFeedback.mediumImpact();
        if (state.canStart || state.isFinished) {
          _freeTimerController.togglePlayPause();
        }
      },
    );
  }

  String _freeTimerPlayButtonLabel(FreeTimerState state) {
    if (state.isFinished) return 'Restart Timer';
    if (state.isRunning) return 'Pause Timer';
    if (state.isPaused) return 'Resume Timer';
    return 'Start Timer';
  }

  String _transitionAlarmTitle(TimerState s) {
    if (s.isAwaitingBreakAcknowledgement) return 'Focus complete';
    return 'Rest complete';
  }

  String _transitionAlarmMessage(TimerState s) {
    if (s.isAwaitingBreakAcknowledgement) {
      return 'Confirm you are here to start rest.';
    }
    return 'Confirm you are here to start focus.';
  }

  String _playButtonLabel(TimerState s) {
    if (s.isSetComplete) return 'Restart Orbit';
    if (_isActiveBreakState(s)) {
      return _isActiveRunningState(s) ? 'Pause Rest' : 'Start Rest';
    }
    return _isActiveRunningState(s) ? 'Pause Focus' : 'Start Focus';
  }

  bool _isActiveBreakState(TimerState s) => s.isOnBreak;

  bool _isActiveRunningState(TimerState s) => s.isRunning || s.isBreakRunning;
}

class _TransitionAlarmPanel extends StatelessWidget {
  const _TransitionAlarmPanel({
    required this.title,
    required this.message,
    required this.accentColor,
    required this.onAcknowledge,
  });

  final String title;
  final String message;
  final Color accentColor;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: '$title. $message',
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: _SpaceshipTimerScreenState._panel.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.52),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.18),
              blurRadius: 24,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.notifications_active_rounded,
              color: accentColor,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              title.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: accentColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _SpaceshipTimerScreenState._textLight.withValues(
                  alpha: 0.70,
                ),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              button: true,
              label: 'I am here',
              child: GestureDetector(
                onTap: onAcknowledge,
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.62),
                      width: 1.3,
                    ),
                  ),
                  child: Text(
                    'I AM HERE',
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtmosphereOrb extends StatelessWidget {
  const _AtmosphereOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchModeButton extends StatelessWidget {
  const _SwitchModeButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _SpaceshipTimerScreenState._panel.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: color.withValues(alpha: 0.42), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.10),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swap_horiz_rounded, color: color, size: 17),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetroHeaderButton extends StatelessWidget {
  const _RetroHeaderButton({
    required this.icon,
    required this.semanticLabel,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _SpaceshipTimerScreenState._panel.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: color.withValues(alpha: 0.36), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.10),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 19),
        ),
      ),
    );
  }
}

class _RetroInfoDialog extends StatelessWidget {
  const _RetroInfoDialog({
    required this.title,
    required this.accentColor,
    required this.children,
  });

  final String title;
  final Color accentColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        decoration: BoxDecoration(
          color: const Color(0xFF111D3A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: accentColor.withValues(alpha: 0.34), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.14),
              blurRadius: 28,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RetroStatRow extends StatelessWidget {
  const _RetroStatRow({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF081329),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: _SpaceshipTimerScreenState._textLight,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RetroFlightHeatmap extends StatelessWidget {
  const _RetroFlightHeatmap({
    required this.statistics,
    required this.now,
    required this.accentColor,
    required this.emptyColor,
    required this.textColor,
  });

  static const int _weekCount = 6;
  static const int _daysPerWeek = 7;
  static const List<String> _weekdayLabels = [
    'M',
    'T',
    'W',
    'T',
    'F',
    'S',
    'S'
  ];

  final TimerStatistics statistics;
  final DateTime now;
  final Color accentColor;
  final Color emptyColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final days = _heatmapDays(now);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF081329),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accentColor.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'LAST 6 WEEKS',
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.78),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.2,
                  ),
                ),
              ),
              Text(
                'FLIGHT TIME',
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Column(
                  children: [
                    for (var weekday = 0;
                        weekday < _weekdayLabels.length;
                        weekday++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: weekday == _weekdayLabels.length - 1 ? 0 : 5,
                        ),
                        child: _HeatmapWeekdayLabel(_weekdayLabels[weekday]),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    for (var week = 0; week < _weekCount; week++) ...[
                      if (week > 0) const SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          children: [
                            for (var weekday = 0;
                                weekday < _daysPerWeek;
                                weekday++)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: weekday == _daysPerWeek - 1 ? 0 : 5,
                                ),
                                child: _HeatmapDayCell(
                                  day: days[week * _daysPerWeek + weekday],
                                  seconds: _secondsForDay(
                                    days[week * _daysPerWeek + weekday],
                                  ),
                                  accentColor: accentColor,
                                  emptyColor: emptyColor,
                                  textColor: textColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _secondsForDay(DateTime day) {
    return statistics.focusSecondsByDay[_dayKey(day)] ?? 0;
  }

  static List<DateTime> _heatmapDays(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final endOfWeek =
        today.add(Duration(days: DateTime.sunday - today.weekday));
    final firstDay = endOfWeek.subtract(
      const Duration(days: _weekCount * _daysPerWeek - 1),
    );
    return List<DateTime>.generate(
      _weekCount * _daysPerWeek,
      (index) => firstDay.add(Duration(days: index)),
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

class _HeatmapWeekdayLabel extends StatelessWidget {
  const _HeatmapWeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: _SpaceshipTimerScreenState._muted.withValues(alpha: 0.86),
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _HeatmapDayCell extends StatelessWidget {
  const _HeatmapDayCell({
    required this.day,
    required this.seconds,
    required this.accentColor,
    required this.emptyColor,
    required this.textColor,
  });

  final DateTime day;
  final int seconds;
  final Color accentColor;
  final Color emptyColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final active = seconds > 0;
    final color = _cellColor();
    final label = active ? _formatCellDuration(seconds) : '';

    return Semantics(
      label:
          '${day.day}.${day.month}: ${active ? _formatSemanticDuration(seconds) : 'no flight time'}',
      child: Container(
        height: 24,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: active
                ? accentColor.withValues(alpha: 0.42)
                : emptyColor.withValues(alpha: 0.16),
            width: 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: TextStyle(
            color: active ? const Color(0xFF06101F) : textColor,
            fontSize: 8.5,
            fontWeight: FontWeight.w900,
            height: 1,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  Color _cellColor() {
    if (seconds <= 0) {
      return emptyColor.withValues(alpha: 0.10);
    }

    return switch (seconds) {
      < 30 * 60 =>
        Color.lerp(emptyColor, accentColor, 0.18)!.withValues(alpha: 0.52),
      < 60 * 60 =>
        Color.lerp(emptyColor, accentColor, 0.42)!.withValues(alpha: 0.70),
      < 90 * 60 => Color.lerp(accentColor, const Color(0xFF5CF0C8), 0.35)!
          .withValues(alpha: 0.82),
      < 120 * 60 => Color.lerp(accentColor, const Color(0xFF5CF0C8), 0.68)!
          .withValues(alpha: 0.90),
      _ => const Color(0xFF5CF0C8).withValues(alpha: 0.95),
    };
  }

  static String _formatCellDuration(int totalSeconds) {
    final totalMinutes = (totalSeconds / 60).round();
    if (totalMinutes <= 0) return '<1m';

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours <= 0) return '${totalMinutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h$minutes';
  }

  static String _formatSemanticDuration(int totalSeconds) {
    final totalMinutes = (totalSeconds / 60).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours <= 0) return '$totalMinutes minutes';
    if (minutes == 0) return '$hours hours';
    return '$hours hours $minutes minutes';
  }
}

class _RetroDialogButton extends StatelessWidget {
  const _RetroDialogButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF081329),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.44), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 18,
              spreadRadius: 0,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}
