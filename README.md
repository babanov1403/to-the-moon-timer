# To The Moon Timer

To The Moon Timer is a Flutter Pomodoro app with a retro space theme. The timer turns each focus session into a small spaceship journey: start a focus session, take off, fly through space, land on a new planet, then continue through the Pomodoro cycle.

## Features

- Space-themed Pomodoro timer with custom animated painters.
- Adjustable focus duration from 10 to 90 minutes.
- Default 25-minute focus sessions and 5-minute breaks.
- Four focus sessions per Pomodoro set.
- Set-completion celebration state.
- Pause, resume, restart, and duration picker flows.
- Local focus-time statistics using shared preferences.
- Foreground-task support for more reliable timer behavior.
- Flutter targets for Android, iOS, macOS, Linux, Windows, and Web.

## Project structure

- [lib/main.dart](lib/main.dart) starts Flutter, initializes foreground-task communication, and runs the app.
- [lib/app/pomodoro_app.dart](lib/app/pomodoro_app.dart) defines the root Material app and theme.
- [lib/features/home/presentation/home_screen.dart](lib/features/home/presentation/home_screen.dart) renders the main timer screen.
- [lib/features/timer/application/timer_controller.dart](lib/features/timer/application/timer_controller.dart) contains the Pomodoro countdown state machine.
- [lib/features/timer/application/timer_config.dart](lib/features/timer/application/timer_config.dart) stores timer duration constants.
- [lib/features/timer/application/timer_statistics_store.dart](lib/features/timer/application/timer_statistics_store.dart) persists focus statistics locally.
- [lib/features/timer/domain/timer_statistics.dart](lib/features/timer/domain/timer_statistics.dart) models total and daily focus time.
- [lib/features/timer/presentation/spaceship_timer_screen.dart](lib/features/timer/presentation/spaceship_timer_screen.dart) coordinates the timer UI, animations, and space scene.
- [lib/features/timer/presentation/widgets/space](lib/features/timer/presentation/widgets/space) contains the custom space visuals.
- [assets/branding/to_the_moon_timer_logo.svg](assets/branding/to_the_moon_timer_logo.svg) contains the app logo asset.

## Requirements

- Flutter SDK 3.x.
- Dart SDK compatible with >=3.0.0 <4.0.0.
- A configured device, simulator, emulator, or browser target.

## Getting started

Clone the repository, install dependencies, and run the app:

```sh
git clone git@github.com:babanov1403/to-the-moon-timer.git
cd to-the-moon-timer
flutter pub get
flutter run
```

For web:

```sh
flutter run -d chrome
```

## Useful commands

Analyze the project:

```sh
flutter analyze
```

Run tests:

```sh
flutter test
```

Build a release APK:

```sh
flutter build apk --release
```

Build for web:

```sh
flutter build web
```

## Dependencies

Main dependencies are declared in [pubspec.yaml](pubspec.yaml):

- Flutter SDK.
- flutter_foreground_task for foreground timer communication.
- shared_preferences for local statistics storage.
- wakelock_plus for keeping the screen awake during focus sessions.

## App flow

1. Choose a focus duration.
2. Start the timer to launch the spaceship.
3. Complete a focus session to land on a planet.
4. Take a break.
5. Repeat until four focus sessions are completed.
6. Celebrate the completed Pomodoro set and restart when ready.

## License

This project currently does not include a license file.
