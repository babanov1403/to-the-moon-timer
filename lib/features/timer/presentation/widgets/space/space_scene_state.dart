/// The visual state of the spaceship scene.
enum SpaceSceneState {
  /// Spaceship is sitting on a planet — idle, break, or break-paused.
  landed,

  /// Spaceship is lifting off; planet slides out of view.
  takingOff,

  /// Spaceship is flying through empty space (active focus session).
  flying,

  /// Spaceship is paused mid-flight; ship frozen in space, no planet visible.
  pausedInSpace,

  /// New planet slides in; ship descends to land (completed session).
  landing,
}
