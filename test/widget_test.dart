import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_timer/main.dart';

void main() {
  // ── 1. Default display ────────────────────────────────────────────────────
  testWidgets('Timer screen shows initial 25:00 and Play button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PomodoroApp());

    // Default timer display must be 25:00
    expect(find.text('25:00'), findsOneWidget);

    // Play button visible, Pause button absent
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsNothing);
  });

  // ── 2. Play/Pause button is larger (≥ 120 × 120) ─────────────────────────
  testWidgets('Play/Pause button is at least 120×120 and toggles play/pause',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PomodoroApp());

    // Find the AnimatedContainer that wraps the play icon.
    final Finder containerFinder = find.ancestor(
      of: find.byIcon(Icons.play_arrow_rounded),
      matching: find.byType(AnimatedContainer),
    );
    expect(containerFinder, findsOneWidget);

    final Size size = tester.getSize(containerFinder);
    expect(size.width, greaterThanOrEqualTo(120));
    expect(size.height, greaterThanOrEqualTo(120));

    // Tapping toggles to Pause
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);

    // Tapping again toggles back to Play
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  // ── 3. Tapping time while stopped opens the picker ────────────────────────
  testWidgets('Tapping time display while stopped opens duration picker',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PomodoroApp());

    // Timer is not running – tap the time display
    await tester.tap(find.text('25:00'));
    await tester.pumpAndSettle();

    // The bottom sheet with the CupertinoPicker should appear
    expect(find.byType(CupertinoPicker), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  // ── 4. Selecting a new duration updates the display ───────────────────────
  testWidgets('Selecting a duration in the picker updates the timer display',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PomodoroApp());

    // Open picker (default is 25 min → index 15 in the 10-90 list)
    await tester.tap(find.text('25:00'));
    await tester.pumpAndSettle();

    // Scroll the ListWheelScrollView that backs CupertinoPicker.
    // We want 30 min (index 20). From index 15 we need +5 items.
    // Each item is 48 px; dragging UP moves to higher indices.
    final Finder wheelFinder = find.byType(ListWheelScrollView);
    expect(wheelFinder, findsOneWidget);

    await tester.drag(wheelFinder, const Offset(0, -5 * 48.0));
    await tester.pumpAndSettle();

    // Confirm selection
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Display should now show 30:00
    expect(find.text('30:00'), findsOneWidget);
  });

  // ── 5. Tapping time while running does NOT open the picker ────────────────
  testWidgets('Tapping time display while running does not open picker',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PomodoroApp());

    // Start the timer
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    // Tap the time display while running
    await tester.tap(find.text('25:00'));
    await tester.pumpAndSettle();

    // Picker must NOT appear
    expect(find.byType(CupertinoPicker), findsNothing);
    expect(find.text('Done'), findsNothing);
  });

  // ── 6. Countdown decrements after one second ──────────────────────────────
  testWidgets('Timer decrements after one second', (WidgetTester tester) async {
    await tester.pumpWidget(const PomodoroApp());

    // Start the timer
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    // Advance time by 1 second
    await tester.pump(const Duration(seconds: 1));

    // Timer should now show 24:59
    expect(find.text('24:59'), findsOneWidget);
  });

  // ── 7. Debug button appears in the duration picker ────────────────────────
  testWidgets('Duration picker shows the 10 sec debug button',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PomodoroApp());

    // Open the picker
    await tester.tap(find.text('25:00'));
    await tester.pumpAndSettle();

    // The debug chip must be visible
    expect(find.text('10 sec'), findsOneWidget);
    expect(find.byKey(const Key('debug_10sec_button')), findsOneWidget);
  });

  // ── 8. Selecting the debug option shows 00:10 ─────────────────────────────
  testWidgets('Tapping the debug 10 sec button sets display to 00:10',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PomodoroApp());

    // Open the picker
    await tester.tap(find.text('25:00'));
    await tester.pumpAndSettle();

    // Tap the debug chip
    await tester.tap(find.byKey(const Key('debug_10sec_button')));
    await tester.pumpAndSettle();

    // Sheet should be dismissed and display should show 00:10
    expect(find.byType(CupertinoPicker), findsNothing);
    expect(find.text('00:10'), findsOneWidget);
  });

  // ── 9. Debug countdown decrements from 00:10 ─────────────────────────────
  testWidgets('Debug timer counts down from 00:10 correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PomodoroApp());

    // Select the debug duration
    await tester.tap(find.text('25:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('debug_10sec_button')));
    await tester.pumpAndSettle();

    // Confirm 00:10 is shown
    expect(find.text('00:10'), findsOneWidget);

    // Start the timer
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    // After 1 second it should show 00:09
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('00:09'), findsOneWidget);

    // After 9 more seconds (10 total) the focus session completes and the
    // break starts automatically. The display now shows the debug break
    // duration (00:05) and the pause button is visible (break is running).
    await tester.pump(const Duration(seconds: 9));
    expect(find.text('00:05'), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
  });

  // ── 10. Debug picker not accessible while timer is running ────────────────
  testWidgets('Debug button is not accessible while timer is running',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PomodoroApp());

    // Start the timer immediately (default 25 min)
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    // Attempt to open the picker while running
    await tester.tap(find.text('25:00'));
    await tester.pumpAndSettle();

    // Picker (and debug button) must NOT appear
    expect(find.byType(CupertinoPicker), findsNothing);
    expect(find.byKey(const Key('debug_10sec_button')), findsNothing);
  });

  // ── 11. Focus session completion transitions to break ─────────────────────
  testWidgets(
      'After debug focus session completes, break countdown starts automatically',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PomodoroApp());

    // Select the 10-second debug duration
    await tester.tap(find.text('25:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('debug_10sec_button')));
    await tester.pumpAndSettle();

    // Start the focus timer
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    // Advance past the full 10-second focus session
    await tester.pump(const Duration(seconds: 10));

    // Break should have started automatically — status label shows 'Break time'
    expect(find.text('Break time'), findsOneWidget);

    // Pause button visible (break is running)
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
  });

  // ── 12. Break countdown decrements correctly ──────────────────────────────
  testWidgets('Break countdown decrements from debug break duration',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PomodoroApp());

    // Select the 10-second debug duration
    await tester.tap(find.text('25:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('debug_10sec_button')));
    await tester.pumpAndSettle();

    // Start focus timer and let it complete
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));

    // Break is now running — advance 1 second into the break
    await tester.pump(const Duration(seconds: 1));

    // Display should show 00:04 (5-second debug break minus 1 second)
    expect(find.text('00:04'), findsOneWidget);
  });

  // ── 13. Break can be paused and resumed ───────────────────────────────────
  testWidgets('Break timer can be paused and resumed',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PomodoroApp());

    // Select the 10-second debug duration
    await tester.tap(find.text('25:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('debug_10sec_button')));
    await tester.pumpAndSettle();

    // Start focus timer and let it complete
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));

    // Break is running — pause it
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();

    // Play button should be visible (break paused)
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.text('Break time'), findsOneWidget);

    // Resume the break
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    // Pause button should be visible again (break running)
    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
  });

  // ── 14. Break session completes and shows break complete label ────────────
  testWidgets('Break session completes and shows break complete label',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PomodoroApp());

    // Select the 10-second debug duration
    await tester.tap(find.text('25:00'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('debug_10sec_button')));
    await tester.pumpAndSettle();

    // Start focus timer and let it complete
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));

    // Advance through the full 5-second debug break
    await tester.pump(const Duration(seconds: 5));

    // Break complete label should be shown
    expect(find.text('Break complete!'), findsOneWidget);

    // Timer should show 00:00
    expect(find.text('00:00'), findsOneWidget);

    // Play button visible (break finished, nothing running)
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    expect(find.byIcon(Icons.pause_rounded), findsNothing);
  });
}
