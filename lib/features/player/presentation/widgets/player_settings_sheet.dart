import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../stream/domain/models/audio_language.dart';
import '../../../stream/domain/models/quality_option.dart';
import '../../../stream/domain/models/stream_provider.dart';
import '../../../stream/domain/models/subtitle_track.dart';
import '../../domain/engine/video_playback_engine.dart';

/// Subtitle customization settings.
class SubtitleSettings {
  final double fontSize;
  final double delaySeconds;

  const SubtitleSettings({
    this.fontSize = 18.0,
    this.delaySeconds = 0.0,
  });

  SubtitleSettings copyWith({
    double? fontSize,
    double? delaySeconds,
  }) {
    return SubtitleSettings(
      fontSize: fontSize ?? this.fontSize,
      delaySeconds: delaySeconds ?? this.delaySeconds,
    );
  }
}

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

  final VoidCallback onClose;

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
    required this.onClose,
  });

  @override
  State<PlayerSettingsSheet> createState() => _PlayerSettingsSheetState();
}

class _PlayerSettingsSheetState extends State<PlayerSettingsSheet> {
  int _activeTabIndex = 0;

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
    return Material(
      color: AppColors.surface.withValues(alpha: 0.95),
      child: Container(
        width: 360,
        height: double.infinity,
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: AppColors.border, width: 0.8),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 24,
              offset: Offset(-4, 0),
            ),
          ],
        ),
        child: SafeArea(
          left: false,
          child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: 8,
                top: 8,
                bottom: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Playback Settings',
                    style: AppText.sectionTitle.copyWith(fontSize: 15),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                    tooltip: 'Close Settings',
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_tabs.length, (index) {
                    final isSelected = index == _activeTabIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(_tabs[index]),
                        selected: isSelected,
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.surfaceElevated,
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF0F150D) : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          fontSize: 11.5,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected ? AppColors.accent : Colors.white12,
                          ),
                        ),
                        onSelected: (_) => setState(() => _activeTabIndex = index),
                      ),
                    );
                  }),
                ),
              ),
            ),
            const Divider(color: AppColors.border, height: 16),

            // Tab Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 4,
                ),
                child: _buildTabContent(),
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildQualitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.availableQualities.map((q) {
        final isSelected = q.label == widget.selectedQuality.label;
        final label = q.isAuto
            ? 'Auto (${widget.selectedQuality.height ?? 1080}p)'
            : q.label;

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
            size: 20,
          ),
          title: Text(label, style: AppText.body.copyWith(fontSize: 13)),
          trailing: q.bandwidth != null
              ? Text(
                  '${(q.bandwidth! / 1000).round()} kbps',
                  style: AppText.meta.copyWith(fontSize: 11),
                )
              : null,
          onTap: () => widget.onSelectQuality(q),
        );
      }).toList(),
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
      children: allAudios.map((a) {
        final isSelected = a.code == widget.selectedAudio.code;

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
            size: 20,
          ),
          title: Text(a.label, style: AppText.body.copyWith(fontSize: 13)),
          trailing: Text(
            a.code.toUpperCase(),
            style: AppText.meta.copyWith(fontSize: 11),
          ),
          onTap: () => widget.onSelectAudio(a),
        );
      }).toList(),
    );
  }

  Widget _buildSubtitlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subtitle Track',
          style: AppText.meta.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        ...widget.availableSubtitles.map((sub) {
          final isSelected = sub.id == widget.selectedSubtitle.id;
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.accent : AppColors.textSecondary,
              size: 20,
            ),
            title: Text(sub.label, style: AppText.body.copyWith(fontSize: 13)),
            onTap: () => widget.onSelectSubtitle(sub),
          );
        }),
        const Divider(color: AppColors.border, height: 20),

        // Font Size
        Text(
          'Font Size',
          style: AppText.meta.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [14.0, 18.0, 24.0].map((size) {
            final isSelected = widget.subtitleSettings.fontSize == size;
            final label = size == 14.0 ? 'Small' : size == 18.0 ? 'Normal' : 'Large';
            return ChoiceChip(
              label: Text(label),
              selected: isSelected,
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surfaceElevated,
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF0F150D) : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                fontSize: 11,
              ),
              onSelected: (_) => widget.onUpdateSubtitleSettings(
                widget.subtitleSettings.copyWith(fontSize: size),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Subtitle Sync Delay (±0.5s)
        Text(
          'Subtitle Sync Delay',
          style: AppText.meta.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
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
                  style: AppText.body.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
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
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: speeds.map((speed) {
        final isSelected = widget.currentSpeed == speed;
        return ChoiceChip(
          label: Text('${speed}x'),
          selected: isSelected,
          selectedColor: AppColors.accent,
          backgroundColor: AppColors.surfaceElevated,
          labelStyle: TextStyle(
            color: isSelected ? const Color(0xFF0F150D) : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            fontSize: 12,
          ),
          onSelected: (_) => widget.onSelectSpeed(speed),
        );
      }).toList(),
    );
  }

  Widget _buildAspectSection() {
    return Column(
      children: VideoAspectRatioMode.values.map((mode) {
        final isSelected = widget.currentAspectRatio == mode;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
            size: 20,
          ),
          title: Text(mode.label, style: AppText.body.copyWith(fontSize: 13)),
          onTap: () => widget.onSelectAspectRatio(mode),
        );
      }).toList(),
    );
  }

  Widget _buildSourcesSection() {
    return Column(
      children: widget.availableProviders.map((provider) {
        final isSelected = provider.id == widget.activeProvider.id;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
            color: isSelected ? AppColors.accent : AppColors.textSecondary,
            size: 20,
          ),
          title: Text(provider.displayName, style: AppText.body.copyWith(fontSize: 13)),
          subtitle: Text('ID: ${provider.id}', style: AppText.meta.copyWith(fontSize: 10.5)),
          onTap: () => widget.onSelectProvider(provider),
        );
      }).toList(),
    );
  }
}
