import 'package:flutter/material.dart';
import 'package:anime_stream/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_motion.dart';
import 'floating_nav_bar.dart';

/// App navigation shell displaying the active tab's branch and the floating pill dashboard.
/// Dynamically animates the FloatingNavBar on scroll using Material 3 motion physics,
/// completely isolated from the tab body to prevent scroll stutters.
class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final ValueNotifier<bool> _isNavBarVisibleNotifier = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _isNavBarVisibleNotifier.dispose();
    super.dispose();
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
    if (!_isNavBarVisibleNotifier.value) {
      _isNavBarVisibleNotifier.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final navItems = [
      FloatingNavBarItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: l10n?.tabHome ?? 'Home',
      ),
      const FloatingNavBarItem(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view_rounded,
        label: 'Explore',
      ),
      const FloatingNavBarItem(
        icon: Icons.bookmark_outline_rounded,
        activeIcon: Icons.bookmark_rounded,
        label: 'Library',
      ),
      const FloatingNavBarItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: 'Settings',
      ),
    ];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // Ignore horizontal carousels or nested non-root scroll views
          if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
            return false;
          }

          // Always reveal bar if user is near top of screen
          if (notification.metrics.pixels <= 40) {
            if (!_isNavBarVisibleNotifier.value) {
              _isNavBarVisibleNotifier.value = true;
            }
            return false;
          }

          // If at the bottom boundary (over-scrolling), prevent bar toggling
          if (notification.metrics.extentAfter == 0) {
            return false;
          }

          // Real-time scroll updates with hysteresis to prevent flutter/jitter
          if (notification is ScrollUpdateNotification) {
            final delta = notification.scrollDelta;
            if (delta != null) {
              if (delta > 12.0 && _isNavBarVisibleNotifier.value) {
                _isNavBarVisibleNotifier.value = false;
              } else if (delta < -10.0 && !_isNavBarVisibleNotifier.value) {
                _isNavBarVisibleNotifier.value = true;
              }
            }
          }
          return false;
        },
        child: Stack(
          children: [
            // Active tab content branch (isolated from nav bar visibility animations)
            Positioned.fill(
              child: widget.navigationShell,
            ),

            // Material 3 Docked Dashboard with M3 motion physics slide
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RepaintBoundary(
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isNavBarVisibleNotifier,
                  builder: (context, isVisible, child) {
                    final duration = isVisible ? AppMotion.medium2 : AppMotion.medium1;
                    return AnimatedSlide(
                      offset: isVisible ? Offset.zero : const Offset(0, 1.05),
                      duration: duration,
                      curve: isVisible
                          ? AppMotion.expressiveFastSpatial
                          : AppMotion.emphasizedAccelerate,
                      child: AnimatedOpacity(
                        opacity: isVisible ? 1.0 : 0.0,
                        duration: duration,
                        curve: AppMotion.standard,
                        child: IgnorePointer(
                          ignoring: !isVisible,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: FloatingNavBar(
                    currentIndex: widget.navigationShell.currentIndex,
                    onTap: _onTap,
                    items: navItems,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
