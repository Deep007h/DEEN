import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
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
/// canonical stadium capsule active indicator around the icon with label below.
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
    return AppSpacing.floatingBarHeight +
        AppSpacing.floatingBarMarginBottom +
        MediaQuery.paddingOf(context).bottom +
        16.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final navBorderRadius = BorderRadius.circular(AppRadius.floatingBar);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.floatingBarMarginHorizontal,
          0,
          AppSpacing.floatingBarMarginHorizontal,
          AppSpacing.floatingBarMarginBottom,
        ),
        decoration: BoxDecoration(
          borderRadius: navBorderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.38),
              blurRadius: 24,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: navBorderRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              height: AppSpacing.floatingBarHeight,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer.withValues(alpha: 0.94),
                borderRadius: navBorderRadius,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: 0.9,
                ),
              ),
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
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = colorScheme.primary;
    final activeBgColor = colorScheme.secondaryContainer;
    final inactiveColor = colorScheme.onSurfaceVariant;

    return Semantics(
      selected: isSelected,
      button: true,
      label: item.label,
      child: PressableScale(
        targetScale: 0.93,
        enableHaptics: false,
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: AppMotion.medium1,
                curve: Curves.easeOutCubic,
                width: isSelected ? 56.0 : 42.0,
                height: 30.0,
                decoration: BoxDecoration(
                  color: isSelected ? activeBgColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(15.0),
                  border: isSelected
                      ? Border.all(
                          color: activeColor.withValues(alpha: 0.28),
                          width: 1.0,
                        )
                      : null,
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: AppMotion.short3,
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: Icon(
                      isSelected ? item.activeIcon : item.icon,
                      key: ValueKey(isSelected),
                      size: 21,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

