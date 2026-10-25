import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_motion.dart';
import 'pressable_scale.dart';

/// Navigation item definition for the floating pill bar.
class FloatingNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FloatingNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Floating pill bottom navigation bar matching Material 3 specifications:
/// Features M3 surfaceContainer elevation, subtle border, and
/// dynamic rounded capsule active indicator overlay surrounding both the icon and tab label.
class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavBarItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  /// Computes dynamic bottom safe padding for scrollable views so content is not obscured by the bar.
  static double getBottomPadding(BuildContext context) {
    return 72.0 + MediaQuery.paddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF50D120D),
        border: Border(
          top: BorderSide(
            color: Color(0x334E604E),
            width: 0.9,
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Padding(
            padding: EdgeInsets.only(
              top: 6.0,
              bottom: bottomSafe > 0 ? bottomSafe : 8.0,
            ),
            child: SizedBox(
              height: 56.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;
                  return Expanded(
                    child: _NavBarTabButton(
                      item: item,
                      isSelected: isSelected,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(index);
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarTabButton extends StatelessWidget {
  final FloatingNavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarTabButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeLime = Color(0xFFB5F237);
    const inactiveColor = Color(0xFF8F9C8F);

    return Semantics(
      selected: isSelected,
      button: true,
      label: item.label,
      child: PressableScale(
        targetScale: 0.92,
        enableHaptics: false,
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Active Solid Lime Capsule or Inactive Box
              AnimatedContainer(
                duration: AppMotion.short3,
                curve: AppMotion.hyperOsSpring,
                width: 64.0,
                height: 31.0,
                decoration: BoxDecoration(
                  color: isSelected ? activeLime : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: AppMotion.short2,
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                        CurvedAnimation(parent: anim, curve: AppMotion.hyperOsSpring),
                      ),
                      child: child,
                    ),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      key: ValueKey(isSelected),
                      size: 21,
                      color: isSelected ? const Color(0xFF0C100C) : inactiveColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: AppMotion.short3,
                curve: AppMotion.hyperOsSpring,
                style: TextStyle(
                  color: isSelected ? activeLime : inactiveColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10.5,
                  letterSpacing: -0.1,
                  fontFamily: 'Inter',
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

