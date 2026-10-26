import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../stream/domain/models/audio_language.dart';
import '../../../stream/domain/models/quality_option.dart';
import '../../../stream/domain/models/stream_provider.dart';
import '../../../stream/domain/models/subtitle_track.dart';
import '../../domain/engine/video_playback_engine.dart';

/// Landscape side sheet providing player configuration controls:
/// - Quality
/// - Audio (Sub/Dub)
/// - Subtitles (Tracks, font size, sync delay)
/// - Playback speed
/// - Aspect ratio mode
/// - Source provider switcher
class PlayerSettingsSheet extends StatefulWidget {
  final List<QualityOption> availableQualities;
  final QualityOption selectedQuality;
  final ValueChanged<QualityOption> onSelectQuality;

  final List<AudioLanguage> availableAudios;
  final AudioLanguage selectedAudio;
  final ValueChanged<AudioLanguage> onSelectAudio;

  final List<SubtitleTrack> availableSubtitles;
  final SubtitleTrack selectedSubtitle;
  final ValueChanged<SubtitleTrack> onSelectSubtitle;

  final SubtitleSettings subtitleSettings;
  final ValueChanged<SubtitleSettings> onUpdateSubtitleSettings;

  final double currentSpeed;
  final ValueChanged<double> onSelectSpeed;

  final VideoAspectRatioMode currentAspectRatio;
  final ValueChanged<VideoAspectRatioMode> onSelectAspectRatio;

  final List<StreamProvider> availableProviders;
  final StreamProvider activeProvider;
  final ValueChanged<StreamProvider> onSelectProvider;

  final double? currentVolume;
  final ValueChanged<double>? onSelectVolume;

  final VoidCallback onClose;
  final int initialTabIndex;

  const PlayerSettingsSheet({
    super.key,
    required this.availableQualities,
    required this.selectedQuality,
    required this.onSelectQuality,
    required this.availableAudios,
    required this.selectedAudio,
    required this.onSelectAudio,
    required this.availableSubtitles,
    required this.selectedSubtitle,
    required this.onSelectSubtitle,
    required this.subtitleSettings,
    required this.onUpdateSubtitleSettings,
    required this.currentSpeed,
    required this.onSelectSpeed,
    required this.currentAspectRatio,
    required this.onSelectAspectRatio,
    required this.availableProviders,
    required this.activeProvider,
    required this.onSelectProvider,
    this.currentVolume,
    this.onSelectVolume,
    required this.onClose,
    this.initialTabIndex = 0,
  });

  @override
  State<PlayerSettingsSheet> createState() => _PlayerSettingsSheetState();
}

class _PlayerSettingsSheetState extends State<PlayerSettingsSheet> {
  late int _activeTabIndex;

  @override
  void initState() {
    super.initState();
    _activeTabIndex = widget.initialTabIndex;
  }

  final _tabs = const [
    'Quality',
    'Audio',
    'Subtitles',
    'Speed',
    'Aspect',
    'Sources',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(6, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border,
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
          // Header matching reference image: Title on left, squircle 'X' close button on right
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Playback Settings',
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
                    onTap: widget.onClose,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHighlight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.0,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Horizontal Pill Tabs: scrollable capsules
          SizedBox(
            height: 38,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(_tabs.length, (index) {
                  final isSelected = index == _activeTabIndex;
                  return Padding(
                    padding: EdgeInsets.only(right: index == _tabs.length - 1 ? 0 : 6),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => _activeTabIndex = index),
                        borderRadius: BorderRadius.circular(19),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(19),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.border,
                              width: 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _tabs[index],
                            style: TextStyle(
                              color: isSelected ? AppColors.accentContrast : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                              fontSize: 11.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const Divider(color: AppColors.borderSubtle, height: 1),

          // Tab Content Area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: _buildTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return _buildQualitySection();
      case 1:
        return _buildAudioSection();
      case 2:
        return _buildSubtitlesSection();
      case 3:
        return _buildSpeedSection();
      case 4:
        return _buildAspectSection();
      case 5:
        return _buildSourcesSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.surfaceHighlight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required bool isSelected,
    required String title,
    String? subtitle,
    String? badge,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent.withValues(alpha: 0.16) : AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.accent : AppColors.border,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Radio indicator matching reference image
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.accent : AppColors.textMuted,
                      width: 2.0,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
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
                      color: AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (trailingText != null)
                  Text(
                    trailingText,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQualitySection() {
    final qualities = widget.availableQualities.isNotEmpty
        ? widget.availableQualities
        : [
            QualityOption.auto(currentHeight: widget.selectedQuality.height ?? 1080),
            const QualityOption(label: '1080p', height: 1080, bandwidth: 5500000),
            const QualityOption(label: '720p', height: 720, bandwidth: 2800000),
            const QualityOption(label: '360p', height: 360, bandwidth: 800000),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.tv_rounded,
          'Video Quality',
          'Select stream resolution',
        ),
        ...qualities.map((q) {
          final isSelected = q.isAuto
              ? widget.selectedQuality.isAuto
              : (!widget.selectedQuality.isAuto && q.label == widget.selectedQuality.label);

          final displayTitle = q.isAuto
              ? 'Auto (${widget.selectedQuality.height ?? 1080}p)'
              : q.label;

          final subtitle = q.isAuto ? 'Best available based on network' : null;

          String? badge;
          if (q.height == 1080 || q.label.contains('1080')) {
            badge = 'FHD';
          } else if (q.height == 720 || q.label.contains('720')) {
            badge = 'HD';
          } else if (q.height == 360 || q.label.contains('360')) {
            badge = 'SD';
          }

          String? bitrateText;
          if (q.bandwidth != null) {
            bitrateText = '${(q.bandwidth! / 1000).round()} kbps';
          } else if (q.height == 1080 || q.label.contains('1080')) {
            bitrateText = '5500 kbps';
          } else if (q.height == 720 || q.label.contains('720')) {
            bitrateText = '2800 kbps';
          } else if (q.height == 360 || q.label.contains('360')) {
            bitrateText = '800 kbps';
          }

          return _buildSettingCard(
            isSelected: isSelected,
            title: displayTitle,
            subtitle: subtitle,
            badge: badge,
            trailingText: bitrateText,
            onTap: () => widget.onSelectQuality(q),
          );
        }),
      ],
    );
  }

  Widget _buildAudioSection() {
    final allAudios = <AudioLanguage>[...widget.availableAudios];
    if (!allAudios.any((a) => a.code == AudioLanguage.japaneseOriginal.code)) {
      allAudios.insert(0, AudioLanguage.japaneseOriginal);
    }
    if (!allAudios.any((a) => a.code == AudioLanguage.englishDub.code)) {
      allAudios.add(AudioLanguage.englishDub);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.onSelectVolume != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          (widget.currentVolume ?? 1.0) <= 0.0
                              ? Icons.volume_off_rounded
                              : (widget.currentVolume ?? 1.0) < 0.5
                                  ? Icons.volume_down_rounded
                                  : Icons.volume_up_rounded,
                          color: AppColors.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Media Volume',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${(((widget.currentVolume ?? 1.0).clamp(0.0, 1.0)) * 100).round()}%',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: AppColors.border,
                    thumbColor: AppColors.accent,
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: (widget.currentVolume ?? 1.0).clamp(0.0, 1.0),
                    onChanged: (v) => widget.onSelectVolume?.call(v),
                  ),
                ),
              ],
            ),
          ),
        ],
        _buildSectionHeader(
          Icons.volume_up_rounded,
          'Audio Track',
          'Select language / dub track',
        ),
        ...allAudios.map((a) {
          final isSelected = a.code == widget.selectedAudio.code;
          final isDub = a.code == AudioLanguage.englishDub.code;
          return _buildSettingCard(
            isSelected: isSelected,
            title: a.label,
            badge: isDub ? 'DUB' : 'ORIGINAL',
            trailingText: a.code.toUpperCase(),
            onTap: () => widget.onSelectAudio(a),
          );
        }),
      ],
    );
  }

  Widget _buildSubtitlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.subtitles_rounded,
          'Subtitles',
          'Select subtitle track and style',
        ),
        ...widget.availableSubtitles.map((sub) {
          final isSelected = sub.id == widget.selectedSubtitle.id;
          return _buildSettingCard(
            isSelected: isSelected,
            title: sub.label,
            trailingText: sub.languageCode.toUpperCase(),
            onTap: () => widget.onSelectSubtitle(sub),
          );
        }),
        const Divider(color: AppColors.borderSubtle, height: 20),

        // Font Size
        const Text(
          'Font Size',
          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [14.0, 18.0, 24.0].map((size) {
            final isSelected = widget.subtitleSettings.fontSize == size;
            final label = size == 14.0 ? 'Small' : size == 18.0 ? 'Normal' : 'Large';
            return ChoiceChip(
              showCheckmark: false,
              label: Text(label),
              selected: isSelected,
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surfaceHighlight,
              labelStyle: TextStyle(
                color: isSelected ? AppColors.accentContrast : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                fontSize: 11,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.accent : AppColors.border,
              ),
              onSelected: (_) => widget.onUpdateSubtitleSettings(
                widget.subtitleSettings.copyWith(fontSize: size),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Subtitle Sync Delay (±0.5s)
        const Text(
          'Subtitle Sync Delay',
          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => widget.onUpdateSubtitleSettings(
                widget.subtitleSettings.copyWith(
                  delaySeconds: widget.subtitleSettings.delaySeconds - 0.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                side: const BorderSide(color: AppColors.border),
              ),
              child: const Text('-0.5s', style: TextStyle(fontSize: 11)),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${widget.subtitleSettings.delaySeconds >= 0 ? '+' : ''}${widget.subtitleSettings.delaySeconds.toStringAsFixed(1)}s',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
                ),
              ),
            ),
            OutlinedButton(
              onPressed: () => widget.onUpdateSubtitleSettings(
                widget.subtitleSettings.copyWith(
                  delaySeconds: widget.subtitleSettings.delaySeconds + 0.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                side: const BorderSide(color: AppColors.border),
              ),
              child: const Text('+0.5s', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeedSection() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.speed_rounded,
          'Playback Speed',
          'Adjust video playback rate',
        ),
        ...speeds.map((speed) {
          final isSelected = widget.currentSpeed == speed;
          return _buildSettingCard(
            isSelected: isSelected,
            title: '${speed}x',
            subtitle: speed == 1.0 ? 'Normal speed' : null,
            badge: speed == 2.0 ? 'MAX' : null,
            onTap: () => widget.onSelectSpeed(speed),
          );
        }),
      ],
    );
  }

  Widget _buildAspectSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.aspect_ratio_rounded,
          'Aspect Ratio',
          'Video framing mode',
        ),
        ...VideoAspectRatioMode.values.map((mode) {
          final isSelected = widget.currentAspectRatio == mode;
          return _buildSettingCard(
            isSelected: isSelected,
            title: mode.label,
            onTap: () => widget.onSelectAspectRatio(mode),
          );
        }),
      ],
    );
  }

  Widget _buildSourcesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          Icons.dns_rounded,
          'Stream Server',
          'Switch streaming server',
        ),
        ...List.generate(widget.availableProviders.length, (index) {
          final provider = widget.availableProviders[index];
          final isSelected = provider.id == widget.activeProvider.id;
          return _buildSettingCard(
            isSelected: isSelected,
            title: 'Server ${index + 1}',
            subtitle: isSelected ? 'Active Stream Server' : 'Fast & Reliable Server',
            onTap: () => widget.onSelectProvider(provider),
          );
        }),
      ],
    );
  }
}
