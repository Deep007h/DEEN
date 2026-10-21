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
  final Widget toHeroWidget = (toHeroContext.widget as Hero).child;
  return Material(
    type: MaterialType.transparency,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: toHeroWidget,
    ),
  );
}
