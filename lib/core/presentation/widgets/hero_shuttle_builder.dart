import 'package:flutter/material.dart';

/// Smooth hero flight shuttle builder ensuring transparent background,
/// anti-aliased rounded corners, and avoiding layout flashes during route transitions.
Widget smoothHeroFlightShuttleBuilder(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final Hero toHero = toHeroContext.widget as Hero;
  final Hero fromHero = fromHeroContext.widget as Hero;
  final Widget displayWidget =
      flightDirection == HeroFlightDirection.push ? toHero.child : fromHero.child;

  final fromRadius = flightDirection == HeroFlightDirection.push ? 16.0 : 14.0;
  final toRadius = flightDirection == HeroFlightDirection.push ? 14.0 : 16.0;

  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final t = animation.value;
      final currentRadius = fromRadius + (toRadius - fromRadius) * t;
      return Material(
        type: MaterialType.transparency,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(currentRadius),
          clipBehavior: Clip.antiAlias,
          child: displayWidget,
        ),
      );
    },
  );
}
