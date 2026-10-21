import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../presentation/widgets/app_shell.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/explore/presentation/screens/explore_screen.dart';
import '../../features/library/presentation/screens/library_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/detail/presentation/screens/detail_screen.dart';
import '../../features/player/presentation/screens/player_screen.dart';

import '../../features/settings/presentation/screens/sources_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// App routing table powered by GoRouter.
/// StatefulShellRoute preserves state and scroll positions across the 4 navigation tabs.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Tab 1: Explore (Categories, seasonal, charts)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/explore',
              name: 'explore',
              builder: (context, state) => const ExploreScreen(),
            ),
          ],
        ),
        // Tab 2: Library (Unified Following & Watch history)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/library',
              name: 'library',
              builder: (context, state) => const LibraryScreen(),
            ),
          ],
        ),
        // Tab 3: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings_tab',
              name: 'settings_tab',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Fullscreen routes outside the navigation shell (no floating bottom bar)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings',
      name: 'settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0.25, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return SlideTransition(
            position: slide,
            child: FadeTransition(opacity: fade, child: child),
          );
        },
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/settings/sources',
      name: 'sources',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SourcesScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slide = Tween<Offset>(
            begin: const Offset(0.25, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
          return SlideTransition(
            position: slide,
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/search',
      name: 'search',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SearchScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final scale = Tween<double>(begin: 0.94, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(animation);
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
          return ScaleTransition(
            scale: scale,
            child: FadeTransition(opacity: fade, child: child),
          );
        },
      ),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/anime/:id',
      name: 'anime_detail',
      pageBuilder: (context, state) {
        final animeId = state.pathParameters['id'] ?? '';
        String? heroTag = state.uri.queryParameters['heroTag'];
        String? previewPoster = state.uri.queryParameters['poster'];
        String? previewTitle = state.uri.queryParameters['title'];
        if (state.extra is Map) {
          final extraMap = state.extra as Map;
          heroTag ??= extraMap['heroTag'] as String?;
          previewPoster ??= (extraMap['posterUrl'] ?? extraMap['previewPoster']) as String?;
          previewTitle ??= (extraMap['title'] ?? extraMap['previewTitle']) as String?;
        }
        return CustomTransitionPage(
          key: state.pageKey,
          transitionDuration: const Duration(milliseconds: 440),
          reverseTransitionDuration: const Duration(milliseconds: 360),
          child: DetailScreen(
            animeId: animeId,
            heroTag: heroTag,
            previewPoster: previewPoster,
            previewTitle: previewTitle,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeOutCubic,
            );
            final scale = Tween<double>(
              begin: 0.965,
              end: 1.0,
            ).animate(curvedAnimation);
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeOutCubic,
            );
            return ScaleTransition(
              scale: scale,
              child: FadeTransition(
                opacity: fade,
                child: child,
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/player',
      name: 'player',
      pageBuilder: (context, state) {
        final animeIdStr = state.uri.queryParameters['animeId'];
        final epStr = state.uri.queryParameters['ep'] ?? state.uri.queryParameters['episode'];
        final providerId = state.uri.queryParameters['provider'];

        final animeId = int.tryParse(animeIdStr ?? '') ?? 400602;
        final episodeNumber = int.tryParse(epStr ?? '') ?? 1;

        // Immediately request landscape orientation upon route initiation to eliminate rotation delay
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

        return CustomTransitionPage(
          key: const ValueKey('player_screen_route'),
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          child: PlayerScreen(
            animeId: animeId,
            episodeNumber: episodeNumber,
            preferredProviderId: providerId,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeOutCubic,
            );

            // Smooth cinematic zoom scale without jagged corner tilts
            final scale = Tween<double>(
              begin: 0.96,
              end: 1.0,
            ).animate(curvedAnimation);

            // Clean full-range opacity fade
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeOutCubic,
            );

            return ScaleTransition(
              scale: scale,
              child: FadeTransition(
                opacity: fade,
                child: child,
              ),
            );
          },
        );
    },
  ),
],
errorBuilder: (context, state) => Scaffold(
  backgroundColor: const Color(0xFF0B0E0B),
  body: Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Color(0xFFC6F16D),
          ),
          const SizedBox(height: 16),
          const Text(
            'Page Not Found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.error?.message ?? 'The requested page could not be located.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8E9E8E),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC6F16D),
              foregroundColor: const Color(0xFF0B0E0B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    ),
  ),
),
);
