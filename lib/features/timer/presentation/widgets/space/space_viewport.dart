import 'package:flutter/material.dart';
import 'planet_data.dart';
import 'ship_style.dart';
import 'space_palette.dart';
import 'space_scene_painter.dart';
import 'space_scene_state.dart';

/// Renders the animated retro arcade space scene inside a bordered window.
class SpaceViewport extends StatelessWidget {
  const SpaceViewport({
    super.key,
    required this.state,
    required this.planet,
    required this.flightController,
    required this.transitionController,
    required this.exhaustController,
    required this.starController,
    required this.isPaused,
    this.shipStyle = const ShipStyle(
      bodyColor: SpacePalette.shipBody,
      accentColor: SpacePalette.shipAccent,
      darkColor: SpacePalette.shipDark,
      exhaustHotColor: SpacePalette.exhaustOrange,
      exhaustCoreColor: SpacePalette.exhaustWhite,
    ),
  });

  final SpaceSceneState state;
  final PlanetData planet;
  final AnimationController flightController;
  final AnimationController transitionController;
  final AnimationController exhaustController;
  final AnimationController starController;
  final bool isPaused;
  final ShipStyle shipStyle;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        flightController,
        transitionController,
        exhaustController,
        starController,
      ]),
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                SpacePalette.spaceBgAlt.withValues(alpha: 0.72),
                SpacePalette.spaceBg,
              ],
            ),
            border: Border.all(
              color: shipStyle.bodyColor.withValues(alpha: 0.22),
              width: 1.2,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: shipStyle.bodyColor.withValues(alpha: 0.10),
                blurRadius: 24,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: CustomPaint(
              painter: SpaceScenePainter(
                state: state,
                planet: planet,
                flightProgress: flightController.value,
                transitionProgress: transitionController.value,
                exhaustPhase: exhaustController.value,
                starPhase: starController.value,
                isPaused: isPaused,
                shipStyle: shipStyle,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }
}
