import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import 'player_corner_banner_ad.dart';

/// Full-screen in-app WebView player that renders the authorized megavid.buzz
/// iframe embed technique. This is the primary/default player for 100% reliable
/// playback matching the web experience.
class WebEmbedPlayerView extends StatefulWidget {
  final String embedUrl;
  final String title;
  final String episodeSubtitle;
  final VoidCallback onBack;
  final VoidCallback onSwitchToNative;
  final bool isLocked;
  final VoidCallback onToggleLock;
  final String? audioLabel;
  final VoidCallback? onToggleAudio;

  const WebEmbedPlayerView({
    super.key,
    required this.embedUrl,
    required this.title,
    required this.episodeSubtitle,
    required this.onBack,
    required this.onSwitchToNative,
    required this.isLocked,
    required this.onToggleLock,
    this.audioLabel,
    this.onToggleAudio,
  });

  @override
  State<WebEmbedPlayerView> createState() => _WebEmbedPlayerViewState();
}

class _WebEmbedPlayerViewState extends State<WebEmbedPlayerView> {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _controlsVisible = true;
  bool _showUnlockButton = false;
  Timer? _unlockTimer;

  @override
  void initState() {
    super.initState();
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _initWebViewController();
    } else {
      _isLoading = false;
    }
  }

  @override
  void didUpdateWidget(covariant WebEmbedPlayerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.embedUrl != widget.embedUrl && !Platform.environment.containsKey('FLUTTER_TEST')) {
      _loadEmbedHtml();
    }
  }

  void _initWebViewController() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final uri = Uri.tryParse(request.url);
            final host = uri?.host.toLowerCase() ?? '';
            // Block third-party popup ads, trackers, and external redirects
            if (host.contains('teniacites') ||
                host.contains('histats') ||
                host.contains('ad-delivery') ||
                host.contains('popunder') ||
                host.contains('onclick')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            // Strip any injected web ad elements & banners
            _controller?.runJavaScript('''
              try {
                var ad = document.getElementById("ad-slot");
                if (ad) ad.remove();
                var blocked = document.getElementById("blocked-screen");
                if (blocked) blocked.remove();
              } catch(e) {}
            ''');
          },
          onWebResourceError: (WebResourceError error) {
            if (kDebugMode) {
              print('WebEmbedPlayer error: ${error.description}');
            }
          },
        ),
      );

    _loadEmbedHtml();
  }

  void _loadEmbedHtml() {
    setState(() => _isLoading = true);
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <title>DEEN Player</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { width: 100%; height: 100%; background: #000000; overflow: hidden; }
    iframe {
      width: 100%;
      height: 100%;
      border: 0;
      display: block;
      position: absolute;
      top: 0;
      left: 0;
    }
  </style>
</head>
<body>
  <iframe
    id="player-frame"
    src="${widget.embedUrl}"
    width="100%"
    height="100%"
    frameborder="0"
    scrolling="no"
    allowfullscreen="true"
    webkitallowfullscreen="true"
    mozallowfullscreen="true"
    allow="autoplay; fullscreen; picture-in-picture; encrypted-media">
  </iframe>
</body>
</html>
''';

    _controller?.loadHtmlString(html, baseUrl: 'https://megavid.buzz');
  }

  @override
  void dispose() {
    _unlockTimer?.cancel();
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _controller?.loadRequest(Uri.parse('about:blank'));
    }
    super.dispose();
  }

  void _showLockedPrompt() {
    setState(() => _showUnlockButton = true);
    _unlockTimer?.cancel();
    _unlockTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showUnlockButton = false);
    });
  }

  void _toggleControls() {
    if (widget.isLocked) {
      _showLockedPrompt();
      return;
    }
    setState(() => _controlsVisible = !_controlsVisible);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          final screenAspect = screenWidth / (screenHeight > 0 ? screenHeight : 1.0);
          const videoAspect = 16.0 / 9.0;
          double pillarboxWidth = 0.0;
          if (screenAspect > videoAspect) {
            final contentWidth = screenHeight * videoAspect;
            pillarboxWidth = (screenWidth - contentWidth) / 2.0;
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Fullscreen WebView Rendering the Iframe
              if (_controller != null)
                IgnorePointer(
                  ignoring: widget.isLocked,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleControls,
                    child: WebViewWidget(controller: _controller!),
                  ),
                )
              else
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _toggleControls,
                  child: Container(
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: Text(
                      'Web Embed Player: ${widget.embedUrl}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),

              // 2. Loading Spinner with smooth fade-out
              AnimatedSwitcher(
                duration: AppMotion.short4,
                child: _isLoading
                    ? Center(
                        key: const ValueKey('web_embed_loading'),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('web_embed_loaded')),
              ),

              // 2b. Minimal Vertical Banner Ad in non-content pillarbox during web playback
              if (pillarboxWidth >= 40.0)
                Positioned(
                  top: math.max(0.0, (screenHeight - math.min(screenHeight - 16.0, 336.0)) / 2.0),
                  right: math.max(
                    MediaQuery.paddingOf(context).right + 4.0,
                    (pillarboxWidth - math.min(50.0, pillarboxWidth - 8.0)) / 2.0,
                  ),
                  child: PlayerCornerBannerAd(
                    isVisible: !_controlsVisible && !widget.isLocked && !_isLoading,
                    availableWidth: pillarboxWidth,
                    availableHeight: screenHeight,
                  ),
                ),

          // 3. Floating Overlay Top Bar
          if (_controlsVisible && !widget.isLocked)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(top: 14, left: 16, right: 16, bottom: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xDD000000),
                      Color(0x88000000),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      // Back Button
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                        tooltip: 'Back',
                      ),
                      const SizedBox(width: 8),

                      // Anime Title & Episode Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  widget.episodeSubtitle,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    'WEB EMBED (DEFAULT)',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Sub / Dub Toggle Button
                      if (widget.audioLabel != null && widget.onToggleAudio != null) ...[
                        InkWell(
                          onTap: widget.onToggleAudio,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: (widget.audioLabel == 'DUB' ? Colors.amber : AppColors.accent).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (widget.audioLabel == 'DUB' ? Colors.amber : AppColors.accent).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.audiotrack_rounded,
                                  color: widget.audioLabel == 'DUB' ? Colors.amber : AppColors.accent,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  widget.audioLabel!,
                                  style: TextStyle(
                                    color: widget.audioLabel == 'DUB' ? Colors.amber : AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Lock Button
                      IconButton(
                        onPressed: widget.onToggleLock,
                        icon: const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 20),
                        tooltip: 'Lock screen',
                      ),

                      const SizedBox(width: 8),

                      // Switch to Native Player Button
                      InkWell(
                        onTap: widget.onSwitchToNative,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flash_on_rounded, color: Colors.amber, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Native Player',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Floating Left Lock Button (when controls are visible - Safe from camera punch holes)
          if (_controlsVisible && !widget.isLocked)
            Positioned(
              left: math.max(MediaQuery.paddingOf(context).left + 28, 68),
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onToggleLock,
                    borderRadius: BorderRadius.circular(24),
                    child: Tooltip(
                      message: 'Lock Screen',
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 5. Floating Unlock Button (when locked)
          if (widget.isLocked && _showUnlockButton)
            Positioned(
              left: math.max(MediaQuery.paddingOf(context).left + 24, 64),
              top: 0,
              bottom: 0,
              child: Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onToggleLock,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: AppColors.accent, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            blurRadius: 16,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                          const BoxShadow(
                            color: Color(0x99000000),
                            blurRadius: 18,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_open_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Tap to Unlock',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  ),
);
  }
}
