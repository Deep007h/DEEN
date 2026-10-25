import 'package:flutter/material.dart';

/// Landscape side panel for 3-dot overflow options.
/// Shares the identical dark squircle geometry, animations, and typography tokens as [PlayerSettingsSheet].
class PlayerMoreOptionsSheet extends StatelessWidget {
  final VoidCallback onLockPlayer;
  final VoidCallback onPictureInPicture;
  final VoidCallback onSwitchToEmbed;
  final VoidCallback onCopyEmbedUrl;
  final VoidCallback onSelectServer;
  final VoidCallback onDiagnostics;
  final VoidCallback? onOpenDescription;
  final VoidCallback? onDownloadEpisode;
  final bool isDownloaded;
  final bool isDownloading;
  final VoidCallback onClose;

  const PlayerMoreOptionsSheet({
    super.key,
    required this.onLockPlayer,
    required this.onPictureInPicture,
    required this.onSwitchToEmbed,
    required this.onCopyEmbedUrl,
    required this.onSelectServer,
    required this.onDiagnostics,
    this.onOpenDescription,
    this.onDownloadEpisode,
    this.isDownloaded = false,
    this.isDownloading = false,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F140F),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF242E24),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0xAA000000),
            blurRadius: 28,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header matching PlayerSettingsSheet: Title + squircle close button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'More Options',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E281E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF2E3D2E),
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          color: Color(0xFFC0D0C0),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF1C251C)),

          // Scrollable option cards matching settings styling
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              physics: const BouncingScrollPhysics(),
              children: [
                if (onOpenDescription != null)
                  _buildOptionCard(
                    icon: Icons.info_outline_rounded,
                    title: 'Anime Info & Synopsis',
                    subtitle: 'View summary, genres, rating, and details',
                    onTap: onOpenDescription!,
                  ),
                if (onDownloadEpisode != null)
                  _buildOptionCard(
                    icon: isDownloaded
                        ? Icons.download_done_rounded
                        : (isDownloading ? Icons.downloading_rounded : Icons.file_download_outlined),
                    title: isDownloaded
                        ? 'Episode Downloaded'
                        : (isDownloading ? 'Downloading Episode...' : 'Download Episode'),
                    subtitle: isDownloaded
                        ? 'Saved offline in Downloads tab'
                        : 'Save this episode for offline playback',
                    badge: isDownloaded ? 'SAVED' : (isDownloading ? 'SAVING' : 'OFFLINE'),
                    onTap: onDownloadEpisode!,
                  ),
                _buildOptionCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Lock Controls',
                  subtitle: 'Prevent accidental touches on screen',
                  onTap: onLockPlayer,
                ),
                _buildOptionCard(
                  icon: Icons.picture_in_picture_alt_rounded,
                  title: 'Picture in Picture',
                  subtitle: 'Keep playing while using other apps',
                  onTap: onPictureInPicture,
                ),
                _buildOptionCard(
                  icon: Icons.language_rounded,
                  title: 'Web Embed Player',
                  subtitle: 'Switch to web browser streaming view',
                  badge: 'ALTERNATIVE',
                  onTap: onSwitchToEmbed,
                ),
                _buildOptionCard(
                  icon: Icons.link_rounded,
                  title: 'Copy Embed URL',
                  subtitle: 'Copy web player link to clipboard',
                  onTap: onCopyEmbedUrl,
                ),
                _buildOptionCard(
                  icon: Icons.dns_rounded,
                  title: 'Stream Server',
                  subtitle: 'Switch server (Server 1, Server 2, Server 3)',
                  onTap: onSelectServer,
                ),
                _buildOptionCard(
                  icon: Icons.bug_report_outlined,
                  title: 'Stream Diagnostics',
                  subtitle: 'View codec, resolution, and pipeline logs',
                  onTap: onDiagnostics,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFF141A14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF242E24),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E281E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: const Color(0xFFC6F16D), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (badge != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x29C6F16D),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Color(0xFFC6F16D),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF5A665A),
                  size: 13,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
