# Phase 0 — Reconnaissance & Baseline Audit

## 1. Executive Summary & Project Context

DEEN (`anime_stream`) is a production-grade, dark-themed, luxury anime and Asian drama streaming application. The project is built using modern Flutter (Dart) targeting Android (Min SDK 21, Target SDK 35, Compile SDK 36), utilizing Riverpod for reactive state management, MediaKit/ExoPlayer for low-latency HLS/DASH media streaming, and Material 3 design tokens.

```
App name:            DEEN (anime_stream)
Package id:          com.animeapp.anime_stream
UI toolkit:          Flutter / Material Design 3 (uses-material-design: true, ThemeData.useMaterial3: true)
Language:            Dart 3.13.5 (Flutter 3.47.7 stable) / Kotlin 1.9+ (Android embedding)
Min / Target SDK:    21 / 35 (Compile SDK: 36)
Player:              MediaKit (libmpv / ExoPlayer Media3 Android backend) + LocalHlsServer proxy + WebEmbed fallback
Networking:          Dio 5.4.3+1 + Local HLS segment streaming server + custom stream resolvers
Image loading:       CachedNetworkImage 3.3.1
Architecture:        Clean Architecture (Features-based: Domain / Data / Presentation)
DI / State:          Flutter Riverpod 2.5.1 (StateNotifier, AsyncValue, ProviderScope)
Backend / sources:   Multi-source aggregator: MegaVid (megavid.buzz), AniFam, KissKH, Bangumi, AniList
Known problems:      Image memory footprint on long browse sessions, minor radius/tooltip inconsistencies,
                     cold DNS lookup latency on external stream providers.
Test devices / env:  Linux x86_64, Android API 34+ (ARM64 & ARMv7 split targets)
```

---

## 2. Project Map & Architecture

### 2.1 Architecture Overview
The codebase follows Feature-Driven Clean Architecture with strict separation of concerns:
- **`lib/core/`**: Cross-cutting infrastructure:
  - `theme/`: Material 3 design system (`AppTheme`, `AppColors`, `AppMotion`, `AppSpacing`, `AppRadius`, `AppText`).
  - `router/`: Declarative routing via `GoRouter` with `StatefulShellRoute` for seamless 5-tab persistent state.
  - `presentation/`: Shared UI primitives (`AppShell`, `FloatingNavBar`, `PressableScale`, `ShimmerBox`, `HeroShuttleBuilder`).
  - `network/`: Base API client, HTTP interceptors, error mappers.
  - `logging/`: Structured error logging.
- **`lib/features/`**:
  - `home`: Hero spotlight billboard, continue watching, trending/top-rated carousels, genre filtering.
  - `explore`: Curated catalogs, seasonal charts, category browser, ranking lists.
  - `search`: Unified concurrent search merging Anime & K-Drama catalogs, animated filter tabs, trending suggestions.
  - `detail`: Media metadata, synopsis, episode selector, source switcher, bookmark/follow toggle.
  - `player`: Full-featured video player (gesture math, HLS proxy, scrub preview HUD, skip intro, hold 2x speed, lock overlay).
  - `stream`: Domain resolvers, fastest server engine, provider registry, title matcher, local HLS buffer.
  - `metadata`: Remote data sources (Bangumi, AniList), caching layer, search pagination.
  - `library`: Watch history, followed shows, progress tracking.
  - `downloads`: Background download manager and offline file persistence.
  - `settings`: Source management, accent theme customizer, backup/restore, terms.

### 2.2 Screen Inventory Table

| Screen | File(s) | UI Toolkit | State / Provider | Data Source | Notes |
|---|---|---|---|---|---|
| **Home** | `home_screen.dart` | Flutter / M3 | `home_providers.dart`, `accentColorProvider` | Bangumi / AniList / History DB | Hero billboard, pinned pull-to-refresh, carousels |
| **Explore** | `explore_screen.dart` | Flutter / M3 | `explore_providers.dart` | Bangumi categories, seasonal API | Multi-browse carousels, category grid |
| **Search** | `search_screen.dart` | Flutter / M3 | `searchPaginationProvider`, `megaVidProvider` | Bangumi (Anime) + KissKH (K-Drama) | Unified concurrent search, animated filter tabs |
| **Detail** | `detail_screen.dart` | Flutter / M3 | `animeDetailProvider`, `streamProviders` | Bangumi/AniList + Stream Orchestrator | Collapsing app bar, source selector, episode list |
| **Player** | `player_screen.dart` | Flutter / M3 | `activeStreamProvider`, `playerEngineProvider` | LocalHlsServer, MegaVid, AniFam | MediaKit libmpv, gesture HUD, scrub preview, 2x hold |
| **Library** | `library_screen.dart` | Flutter / M3 | `library_providers.dart`, `followRepository` | Local SQLite / SharedPreferences | Following list, watch progress, resume cards |
| **Downloads** | `downloads_screen.dart` | Flutter / M3 | `download_providers.dart` | App storage / path_provider | Offline playback, download progress |
| **Settings** | `settings_screen.dart` | Flutter / M3 | `appSettingsProvider`, `accentColorProvider` | SharedPreferences | Dynamic accent palette picker, player defaults |
| **Sources** | `sources_screen.dart` | Flutter / M3 | `streamProviderRegistry` | Stream provider configs | Server toggles, latency ping tests |
| **Terms** | `terms_conditions_screen.dart` | Flutter / M3 | Static | App bundle | Disclaimer and legal info |

---

## 3. Dependency Audit

### 3.1 Production Dependencies (`pubspec.yaml`)
| Dependency | Declared Version | Resolved / Status | Category | Notes |
|---|---|---|---|---|
| `flutter` | SDK | 3.47.7 (Dart 3.13.5) | Core | Stable channel |
| `flutter_riverpod` | `^2.5.1` | 2.6.1 | State | Riverpod 2.x StateNotifier & AsyncValue |
| `go_router` | `^14.2.0` | 14.8.1 | Navigation | Declarative routing with StatefulShellRoute |
| `dio` | `^5.4.3+1` | 5.4.3+1 | Networking | HTTP client with cancellation and streaming |
| `media_kit` | `^1.2.6` | 1.2.6 | Video | libmpv / Media3 hardware-accelerated playback |
| `media_kit_video` | `^2.0.1` | 2.0.1 | Video | Texture rendering widget for Flutter |
| `media_kit_libs_video`| `^1.0.7`| 1.0.7 | Video | Native C/C++ media decoding binaries |
| `cached_network_image`| `^3.3.1`| 3.4.1 | Image | Memory + disk image caching |
| `shared_preferences` | `^2.2.3` | 2.5.0 | Persistence | Key-value settings storage |
| `sqflite` | (transitive) | 2.4.4+2 | Database | Local SQLite persistence for library/history |
| `wakelock_plus` | `^1.2.8` | 1.8.1 | System | Screen keep-awake during playback |
| `volume_controller` | `^3.7.1` | 3.7.1 | System | Gesture hardware volume control |
| `screen_brightness` | `^2.1.11`| 2.1.11 | System | Gesture vertical brightness slider |
| `startapp_sdk` | `^1.0.1` | 1.0.1 | Ads (Standard only)| Removed/absent in `DEEN_AdFree` |

### 3.2 Material Design 3 Status
- `ThemeData.useMaterial3`: **True** (Enabled globally in `app_theme.dart`).
- Material 2 / legacy imports: **None** found (`com.google.android.material` or `package:flutter/material.dart` with M2 components eliminated).
- Dynamic Tonal Color Scheme: Configured via `ColorScheme.fromSeed(seedColor: accentColor, brightness: Brightness.dark)`.
- Full Surface Container roles: `surfaceContainerLowest`, `surfaceContainerLow`, `surfaceContainer`, `surfaceContainerHigh`, `surfaceContainerHighest` fully mapped.

---

## 4. Baseline Measurements

| Metric | Measurement Method | Baseline Value | Target | Status |
|---|---|---|---|---|
| **Automated Unit & Integration Tests** | `flutter test` | **164 / 164 passed (100%)** in 16.0s | 100% pass | ✅ Green |
| **Static Code Analyzer Issues** | `flutter analyze` | **0 issues found** | 0 issues | ✅ Green |
| **Release APK Size (ARM64)** | `ls -lh build/.../app-arm64-v8a-release.apk` | **40.0 MB** | < 45 MB | ✅ Target Met |
| **Release APK Size (ARMv7)** | `ls -lh build/.../app-armeabi-v7a-release.apk` | **37.0 MB** | < 40 MB | ✅ Target Met |
| **Stream Resolution Latency (Cache)** | In-memory `_resultCache` TTL probe | **< 10 ms** | < 50 ms | ✅ Instant |
| **Stream Resolution Latency (MegaVid)** | Network scrape & playlist extract | **~450 – 850 ms** | < 1200 ms | ✅ Fast |
| **Stream Resolution Latency (Demo)** | Local test streams | **~250 – 380 ms** | < 500 ms | ✅ Fast |
| **Local HLS RAM Segment Buffer** | `LocalHlsServer` buffer queue | **12 segments** (~24–48s video) | 10–15 segs | ✅ Optimized |
| **Pull-to-Refresh Clamping** | `CustomScrollView` physics | Pinned (offset 0 clamped) | Pinned cards | ✅ Verified |
