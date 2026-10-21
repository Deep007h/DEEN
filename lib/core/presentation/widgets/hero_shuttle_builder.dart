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

  final fromRadius = flightDirection == HeroFlightDirection.push ? 16.0 : 13.0;
  final toRadius = flightDirection == HeroFlightDirection.push ? 13.0 : 16.0;

  final curvedAnimation = CurvedAnimation(
    parent: animation,
    curve: Curves.easeInOutCubic,
  );

  return AnimatedBuilder(
    animation: curvedAnimation,
    builder: (context, _) {
      final t = curvedAnimation.value;
      final currentRadius = fromRadius + (toRadius - fromRadius) * t;
      // Mid-flight elevation bump for realistic tactile depth
      final lift = (1.0 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);

      return Material(
        type: MaterialType.transparency,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(currentRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35 + 0.25 * lift),
                blurRadius: 12.0 + 16.0 * lift,
                spreadRadius: 1.0 * lift,
                offset: Offset(0, 4.0 + 8.0 * lift),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(currentRadius),
            clipBehavior: Clip.antiAlias,
            child: SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.antiAlias,
                child: displayWidget,
              ),
            ),
          ),
        ),
      );
    },
  );
}
