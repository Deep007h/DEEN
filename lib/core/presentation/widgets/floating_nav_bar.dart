import 'dart:ui';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
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

/// Floating pill bottom navigation bar matching the Material 3 & user reference design:
/// Features frosted glass blur, subtle neon border, elevated depth shadows,
/// and Material 3 expressive spring physics.
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Responsive horizontal margin for small screens (down to 360px)
    final horizontalMargin = screenWidth < 380 ? 12.0 : AppSpacing.floatingBarMarginHorizontal;

    return Padding(
      padding: EdgeInsets.only(
        left: horizontalMargin,
        right: horizontalMargin,
        bottom: bottomInset > 0 ? bottomInset + 4 : AppSpacing.floatingBarMarginBottom,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24.0, sigmaY: 24.0),
          child: Container(
            height: 66.0,
            decoration: BoxDecoration(
              color: const Color(0xE8101510),
              borderRadius: BorderRadius.circular(34.0),
              border: Border.all(
                color: const Color(0xFFC6F16D).withValues(alpha: 0.20),
                width: 1.0,
              ),
              boxShadow: [
                const BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 30,
                  spreadRadius: 1,
                  offset: Offset(0, 10),
                ),
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 2),
                ),
              ],
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
                    onTap: () => onTap(index),
                  ),
                );
              }),
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
    return Semantics(
      selected: isSelected,
      button: true,
      label: item.label,
      child: PressableScale(
        targetScale: 0.92,
        onTap: onTap,
        child: Center(
          child: AnimatedContainer(
            duration: AppMotion.medium1,
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 18.0 : 10.0,
              vertical: isSelected ? 7.0 : 6.0,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : Colors.transparent,
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: AppMotion.short3,
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    key: ValueKey(isSelected),
                    size: 21,
                    color: isSelected ? const Color(0xFF0B0E0B) : const Color(0xFFA0ACA0),
                  ),
                ),
                const SizedBox(height: 2.5),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF0B0E0B) : const Color(0xFFA0ACA0),
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                    fontSize: 10.5,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

