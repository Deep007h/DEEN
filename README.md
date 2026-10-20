# DEEN

A high-performance, dark-themed anime streaming and library application built with Flutter, Riverpod, and `media_kit`. Features an obsidian & crimson luxury aesthetic, rich metadata with season chains from the Bangumi API, pluggable stream provider resolution (sub/dub, multi-quality), full gesture-driven landscape video player, offline metadata caching, and library tracking.

---

## Architecture Overview

```text
┌────────────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                              │
│                                                                        │
│   AppRouter (GoRouter + StatefulShellRoute)                            │
│   ├── Floating Pill Navigation Bar (Blur / Frosted Glass)              │
│   │   ├── Home Screen (Continue Watching + Search Hero)                │
│   │   ├── Following Screen (追番 grid, unwatched badges, spring star)  │
│   │   ├── Recent Screen (History with resume progress & swipe-delete)  │
│   │   └── Settings Screen (Audio/Sub defaults, Backup/Restore, Sources)│
│   ├── Search Screen (Keyword search, heat/score sort, tag filters)     │
│   ├── Detail Screen (Hero poster, backdrop banner, seasons, episodes)  │
│   └── Player Screen (Fullscreen landscape, media_kit, gesture controls)│
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ (Riverpod Notifiers & Providers)
┌───────────────────────────────────▼────────────────────────────────────┐
│                           DOMAIN LAYER                                 │
│                                                                        │
│   • Models: AnimeDetail, AnimeSummary, Season, Episode, AnimeTitles    │
│   • Stream Contracts: StreamProvider, SourceMatch, SourceEpisode,      │
│     StreamVariant, AudioLanguage, SubtitleTrack, QualityOption         │
│   • Repositories: MetadataRepository, FollowRepository, HistoryRepo    │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                            DATA LAYER                                  │
│                                                                        │
│   • Metadata Sources:                                                  │
│     - Bangumi API (api.bgm.tv) with custom User-Agent & retry backoff  │
│     - MetadataCache (LRU memory cache + offline stale-recovery)        │
│   • Stream Providers:                                                  │
│     - StreamOrchestrator (Provider priority & fallback engine)         │
│     - DemoProvider (Public HLS/MP4 test streams, multi-sub/dub)        │
│     - Pluggable 3rd-party provider interface                           │
│   • Persistence:                                                       │
│     - SharedPreferences / JSON persistence for follows & watch history │
│     - Centralized ErrorLogger & telemetry sink                         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │
┌───────────────────────────────────▼────────────────────────────────────┐
│                          MEDIA ENGINE                                  │
│                                                                        │
│   • media_kit (MPV backend) for hardware-accelerated video rendering   │
│   • Custom HUD overlay: seek bar, double-tap seek, brightness/volume   │
│     vertical swipes, 2x long-press boost, sliding episode drawer       │
└────────────────────────────────────────────────────────────────────────┘
```

---

## Key Features

- **Obsidian & Crimson Design System**:
  - Dark luxury theme tokens (`AppColors.background = #101014`, `AppColors.accent = #E50914`).
  - Floating pill navigation bar with frosted backdrop blur (`BackdropFilter`).
  - Hero image animations between Search, Home, and Detail screens.
  - Interactive spring bounce animation (`Curves.elasticOut`) on the follow star.

- **Bangumi Metadata Engine**:
  - Search anime with sort modes: *Best Match*, *Popularity / Heat*, *Bangumi Score*.
  - Automatic season chains (Prequel / Sequel graph traversal) with interactive season tabs.
  - Japanese, English, and localized title preference support.

- **Pluggable Stream Provider Resolution**:
  - Abstract `StreamProvider` interface separating catalog metadata from video delivery.
  - Multi-track audio support: Japanese Original, English Dub, Hindi Dub, etc.
  - Multi-language subtitles (VTT, SRT, ASS).
  - Multi-quality resolution switching (`360p`, `480p`, `720p`, `1080p`, `Auto`).
  - Diagnostic trace logs viewer for stream resolution debugging.

- **Pro Video Player (`media_kit`)**:
  - Full-screen landscape locking on player open, orientation restored on exit.
  - Double-tap on left/right half to seek ±10 seconds with ripple feedback.
  - Vertical gesture controls: Left side for brightness, right side for volume with animated HUD pills.
  - Long-press anywhere for temporary 2x speed playback with top banner indicator.
  - Next episode countdown card during the last 5 seconds with auto-advance and cancel.
  - Sliding episode selection drawer from right screen edge.

- **Offline & Low-Bandwidth Resilience**:
  - In-memory and disk metadata caching.
  - Stale cache fallback when offline or when network requests fail.
  - Image downsampling (`memCacheWidth` / `memCacheHeight`) to prevent mobile memory bloat.

- **Library & Settings Management**:
  - Unwatched episode counter badges on followed anime.
  - Watch history tracking current playback position, total duration, and completion status.
  - JSON data export and import for seamless backup and cross-device sync.

---

## Setup & Running

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.19.0 or newer
- Android SDK 21+ / Xcode 14+ for iOS

### Installation

1. **Clone the repository and install dependencies**:
   ```bash
   git clone <repo-url>
   cd anime_stream
   flutter pub get
   ```

2. **Generate Freezed and JSON serialization models**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. **Run on connected device or emulator**:
   ```bash
   flutter run
   ```

4. **Run tests**:
   ```bash
   # Run all unit, widget, and integration tests
   flutter test

   # Run the Search -> Detail -> Play integration flow test
   flutter test test/integration/search_to_player_flow_test.dart

   # Analyze code
   flutter analyze
   ```

---

## How to Add a New StreamProvider

To add a new streaming source (e.g. your own media server, WebDAV, or public API), implement the `StreamProvider` interface:

### 1. Create your provider class

```dart
import 'package:anime_stream/features/metadata/domain/models/anime_detail.dart';
import 'package:anime_stream/features/stream/domain/models/models.dart';
import 'package:anime_stream/features/stream/domain/providers/stream_provider.dart';

class CustomMediaProvider implements StreamProvider {
  @override
  String get id => 'custom_provider';

  @override
  String get displayName => 'Custom Media Server';

  @override
  Future<List<SourceMatch>> findTitle(AnimeDetail anime) async {
    // 1. Search your service using anime.titles.preferredTitle() or anime.titles.original
    // 2. Return matching titles with match confidence score (0.0 - 1.0)
    return [
      SourceMatch(
        providerId: id,
        sourceId: 'media_12345',
        title: anime.titles.english ?? anime.titles.original,
        episodeCount: anime.eps,
        confidence: 0.95,
      ),
    ];
  }

  @override
  Future<List<SourceEpisode>> episodes(SourceMatch match) async {
    // Return available episodes for the matched title
    return [
      SourceEpisode(
        id: 'ep_1',
        number: 1.0,
        title: 'Episode 1',
      ),
    ];
  }

  @override
  Future<List<StreamVariant>> resolve(SourceEpisode episode) async {
    // Return playable HLS (.m3u8) or MP4 stream variants with audio and subtitle tracks
    return [
      StreamVariant(
        url: 'https://example.com/hls/ep1/master.m3u8',
        audio: AudioLanguage(code: 'ja', name: 'Japanese (Original)'),
        headers: {'Referer': 'https://example.com'},
        subtitles: [
          SubtitleTrack(
            language: 'English',
            code: 'en',
            url: 'https://example.com/subs/en.vtt',
            format: SubtitleFormat.vtt,
          ),
        ],
        qualities: [
          QualityOption(label: '1080p', resolution: 1080, bitrate: 5000000),
          QualityOption(label: '720p', resolution: 720, bitrate: 2500000),
        ],
      ),
    ];
  }
}
```

### 2. Register the provider

Add your provider to `StreamOrchestrator` in `lib/features/stream/presentation/providers/stream_providers.dart`:

```dart
final streamOrchestratorProvider = Provider<StreamOrchestrator>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StreamOrchestrator(
    providers: [
      DemoProvider(),
      CustomMediaProvider(), // <-- Add here
    ],
    prefs: prefs,
  );
});
```

---

## Permissions & Platform Config

### Android (`android/app/src/main/AndroidManifest.xml`)
- `android.permission.INTERNET`: Network access for metadata APIs and video streaming.
- `android.permission.ACCESS_NETWORK_STATE`: Detecting online/offline status for cache fallback.
- `android.permission.WAKE_LOCK`: Keeping screen awake during video playback.

### iOS (`ios/Runner/Info.plist`)
- `CFBundleDisplayName`: Set to `DEEN`.
- `NSAppTransportSecurity` (`NSAllowsArbitraryLoads: true`): Enables streaming video content across diverse CDN endpoints and HTTP/HTTPS media servers.

---

## Content Disclaimer

> **DISCLAIMER**: DEEN is a client-side catalog browser and video player application. It does not host, archive, transmit, or distribute any media content or copyright-protected files. All anime titles, images, and descriptions are fetched from third-party public metadata APIs (such as Bangumi). Playback relies strictly on user-configured streams or third-party providers. The developers assume no liability for the content loaded or streamed by end users.

---

## Known Issues & Future Roadmap

1. **DRM / Encrypted HLS Streams**:
   - `media_kit` does not currently support Widevine DRM content on mobile without custom native extensions.
2. **Background Audio**:
   - Minimizing the app or locking the screen pauses video playback by default; future versions will support audio-only background service playback.
3. **Danmaku / Live Comments Overlay**:
   - A placeholder button is provided on the player HUD. Integration with Bilibili/Niconico-style rolling bullet-chat comment engines is planned for a future release.
