import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../application/timer_config.dart';
import '../application/timer_controller.dart';
import '../application/timer_formatter.dart';
import '../application/timer_session_runtime.dart';
import '../application/timer_statistics_store.dart';
import '../domain/timer_statistics.dart';
import '../domain/timer_status.dart';
import 'widgets/duration_picker_sheet.dart';
import 'widgets/space/planet_data.dart';
import 'widgets/space/retro_timer_widgets.dart';
import 'widgets/space/space_scene_state.dart';
import 'widgets/space/space_viewport.dart';

/// Home screen: retro arcade Pomodoro timer with a spaceship visual metaphor.
class SpaceshipTimerScreen extends StatefulWidget {
  const SpaceshipTimerScreen({super.key});

  @override
  State<SpaceshipTimerScreen> createState() => _SpaceshipTimerScreenState();
}

class _SpaceshipTimerScreenState extends State<SpaceshipTimerScreen>
    with TickerProviderStateMixin {
  late final TimerController _controller;
  late final TimerStatisticsStore _statisticsStore;
  late final TimerSessionRuntime _sessionRuntime;
  late final AnimationController _exhaustCtrl;
  late final AnimationController _starCtrl;
  late final AnimationController _transitionCtrl;
  late final AnimationController _flightCtrl;
  late final AnimationController _celebrationCtrl;

  SpaceSceneState _scene = SpaceSceneState.landed;
  TimerStatus? _prevStatus;
  TimerStatistics _statistics = TimerStatistics.empty();
  Future<void> _statisticsUpdate = Future<void>.value();
  int? _lastFocusRemainingSeconds;
  PlanetData _planet = PlanetData.generate(42);
  int _planetSeed = 42;
  int _lastCompletedSetCount = 0;
  final List<({Color colorA, Color colorB})> _completedPlanetColors = [];

  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _yellow = Color(0xFFFFFF2E);
  static const Color _muted = Color(0xFF6955C8);
  static const Color _bg = Color(0xFF070015);
  static const Color _textLight = Color(0xFFE9E5FF);

  @override
  void initState() {
    super.initState();
    _controller = TimerController()..addListener(_onTimerChanged);
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
    _sessionRuntime.stop();
    _controller.dispose();
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
    _sessionRuntime.sync(timerState);
    if (status != _prevStatus) _handleTransition(_prevStatus, status);
    if (timerState.completedSetCount > _lastCompletedSetCount) {
      _lastCompletedSetCount = timerState.completedSetCount;
      _celebrationCtrl.forward(from: 0);
    }
    _prevStatus = status;
    _lastFocusRemainingSeconds =
        status == TimerStatus.running ? timerState.remainingSeconds : null;
    setState(() {});
  }

  int _elapsedFocusSeconds(int remainingSeconds) {
    if (_prevStatus != TimerStatus.running ||
        _lastFocusRemainingSeconds == null) {
      return 0;
    }
    return (_lastFocusRemainingSeconds! - remainingSeconds).clamp(0, 3600);
  }

  void _recordFocusSeconds(int seconds) {
    _statisticsUpdate = _statisticsUpdate
        .then((_) => _statisticsStore.addFocusSeconds(seconds))
        .then((statistics) {
      if (mounted) setState(() => _statistics = statistics);
    }).catchError((Object _) {});
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
    } else if ((next == TimerStatus.finished ||
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
    final s = _controller.state;
    final total = s.isDebugMode ? kDebugSeconds : s.selectedMinutes * 60;
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
    _recordCurrentPlanetForCompletedFocus();
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
      s == TimerStatus.breakRunning ||
      s == TimerStatus.breakPaused ||
      s == TimerStatus.breakFinished ||
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

  void _reset() {
    _scene = SpaceSceneState.landed;
    _prevStatus = null;
    _lastCompletedSetCount = _controller.state.completedSetCount;
    _completedPlanetColors.clear();
    _flightCtrl.stop();
    _flightCtrl.reset();
    _celebrationCtrl.stop();
    _celebrationCtrl.reset();
    _lastFocusRemainingSeconds = null;
    setState(() {});
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
            label: 'TOTAL FOCUS',
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
          const SizedBox(height: 24),
          _RetroDialogButton(
            label: 'RESET STATS',
            color: _yellow,
            onTap: () async {
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
    final isActive = s.isRunning || s.isBreakRunning;
    final isBreak = s.isOnBreak;
    final accent = isBreak ? _yellow : _cyan;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
            child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                RetroLabel(text: isBreak ? 'BREAK' : 'FOCUS', color: accent),
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
          ),
          Expanded(
              flex: 5,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SpaceViewport(
                      state: _scene,
                      planet: _planet,
                      flightController: _flightCtrl,
                      transitionController: _transitionCtrl,
                      exhaustController: _exhaustCtrl,
                      starController: _starCtrl,
                      isPaused: s.status == TimerStatus.paused ||
                          s.status == TimerStatus.breakPaused))),
          Expanded(
              flex: 4,
              child: Center(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RetroTimerField(
                      timeLabel: TimerFormatter.format(s.remainingSeconds),
                      isRunning: isActive,
                      accentColor: accent,
                      onTap: _openPicker),
                  const SizedBox(height: 18),
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      RetroPomodoroSetProgress(
                        completedPlanetColors: _completedPlanetColors,
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
                  ),
                ],
              ))),
          Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                RetroModeLabel(
                    label: 'WORK',
                    active: !isBreak,
                    activeColor: _cyan,
                    mutedColor: _muted),
                const SizedBox(width: 32),
                RetroModeLabel(
                    label: 'BREAK',
                    active: isBreak,
                    activeColor: _yellow,
                    mutedColor: _muted),
              ])),
          Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: RetroPlayButton(
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
                  })),
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                  width: 134,
                  height: 5,
                  decoration: BoxDecoration(
                      color: _textLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3)))),
        ])),
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
            color: _SpaceshipTimerScreenState._bg.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.82), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.20),
                blurRadius: 12,
                spreadRadius: 1,
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
          color: const Color(0xFF0F0F2A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accentColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.30),
              blurRadius: 22,
              spreadRadius: 3,
            ),
          ],
        ),
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
                  child:
                      Icon(Icons.close_rounded, color: accentColor, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 22),
            ...children,
          ],
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
        color: const Color(0xFF070015),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
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
          color: const Color(0xFF070015),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.24),
              blurRadius: 14,
              spreadRadius: 1,
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
