import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../metadata/data/repositories/metadata_repository_impl.dart';
import '../../../metadata/domain/models/anime_titles.dart';
import '../../../metadata/presentation/providers/metadata_providers.dart';
import '../../data/repositories/app_settings_repository.dart';
import '../../domain/models/data_backup.dart';

/// Available accent colors in the Appearance settings.
const List<Color> _kAccentColors = [
  Color(0xFFE50914), // Vivid Netflix / Anime Red (Default)
  Color(0xFFFF3B30), // Crimson
  Color(0xFF9D4EDD), // Electric Purple
  Color(0xFF2196F3), // Ocean Blue
  Color(0xFF00E676), // Emerald Green
  Color(0xFFFFB300), // Amber Gold
];

/// Settings tab screen for configuring appearance, playback, sources, and data backup.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.paddingOf(context).top;
    final settings = ref.watch(appSettingsProvider);
    final settingsNotifier = ref.read(appSettingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: AppMotion.m3ScrollPhysics,
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding + AppSpacing.md,
                left: AppSpacing.pageMargin,
                right: AppSpacing.pageMargin,
                bottom: AppSpacing.lg,
              ),
              child: Text(
                l10n.settingsTitle,
                style: AppText.pageTitle,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. APPEARANCE
                  _SectionHeader(title: l10n.appearanceSection),
                  _SettingsCard(
                    children: [
                      // Theme Mode
                      _SettingsTile(
                        icon: Icons.dark_mode_rounded,
                        title: l10n.themeOption,
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: AppRadius.pillBorder,
                            border: Border.all(color: AppColors.accentBorder, width: 0.8),
                          ),
                          child: Text(
                            'Pure Black',
                            style: AppText.badgeText.copyWith(color: AppColors.accent),
                          ),
                        ),
                      ),
                      const Divider(height: 1),

                      // Accent Color Palette
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const _IconBadge(icon: Icons.palette_outlined),
                                const SizedBox(width: AppSpacing.md),
                                Text(
                                  'Accent Color',
                                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: _kAccentColors.map((color) {
                                final isSelected = settings.accentColorValue == color.toARGB32();
                                return GestureDetector(
                                  onTap: () => settingsNotifier.updateAccentColor(color),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? Colors.white : Colors.transparent,
                                        width: 2.5,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: color.withValues(alpha: 0.6),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // Title Language Preference
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const _IconBadge(icon: Icons.translate_rounded),
                                const SizedBox(width: AppSpacing.md),
                                Text(
                                  'Title Language',
                                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<TitlePreference>(
                                segments: const [
                                  ButtonSegment<TitlePreference>(
                                    value: TitlePreference.english,
                                    label: Text('English'),
                                  ),
                                  ButtonSegment<TitlePreference>(
                                    value: TitlePreference.original,
                                    label: Text('Original'),
                                  ),
                                  ButtonSegment<TitlePreference>(
                                    value: TitlePreference.localized,
                                    label: Text('Localized'),
                                  ),
                                ],
                                selected: {settings.titlePreference},
                                onSelectionChanged: (newSelection) {
                                  if (newSelection.isNotEmpty) {
                                    settingsNotifier.updateTitlePreference(newSelection.first);
                                  }
                                },
                                showSelectedIcon: false,
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 2. PLAYBACK
                  const _SectionHeader(title: 'Playback'),
                  _SettingsCard(
                    children: [
                      // Default Quality
                      _SettingsTile(
                        icon: Icons.high_quality_rounded,
                        title: 'Default Quality',
                        trailing: _DropdownPill<String>(
                          value: settings.defaultQuality,
                          items: const ['Auto', '1080p', '720p', '480p'],
                          onChanged: (val) {
                            if (val != null) settingsNotifier.updateDefaultQuality(val);
                          },
                        ),
                      ),
                      const Divider(height: 1),

                      // Default Audio Language
                      _SettingsTile(
                        icon: Icons.record_voice_over_rounded,
                        title: 'Default Audio',
                        trailing: _DropdownPill<String>(
                          value: settings.defaultAudioLanguage,
                          items: const ['Original', 'English', 'Japanese'],
                          onChanged: (val) {
                            if (val != null) settingsNotifier.updateDefaultAudio(val);
                          },
                        ),
                      ),
                      const Divider(height: 1),

                      // Default Subtitle Language
                      _SettingsTile(
                        icon: Icons.subtitles_rounded,
                        title: 'Default Subtitles',
                        trailing: _DropdownPill<String>(
                          value: settings.defaultSubtitleLanguage,
                          items: const ['English', 'Off', 'Spanish'],
                          onChanged: (val) {
                            if (val != null) settingsNotifier.updateDefaultSubtitle(val);
                          },
                        ),
                      ),
                      const Divider(height: 1),

                      // Autoplay Next
                      _SettingsSwitchTile(
                        icon: Icons.skip_next_rounded,
                        title: 'Autoplay Next Episode',
                        subtitle: 'Play next episode automatically when current ends',
                        value: settings.autoplayNext,
                        onChanged: (val) => settingsNotifier.setAutoplayNext(val),
                      ),
                      const Divider(height: 1),

                      // Skip-forward Step (10s, 15s, 30s)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const _IconBadge(icon: Icons.fast_forward_rounded),
                                const SizedBox(width: AppSpacing.md),
                                Text(
                                  'Skip Step',
                                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<int>(
                                segments: const [
                                  ButtonSegment<int>(value: 10, label: Text('10s')),
                                  ButtonSegment<int>(value: 15, label: Text('15s')),
                                  ButtonSegment<int>(value: 30, label: Text('30s')),
                                ],
                                selected: {settings.skipStepSeconds},
                                onSelectionChanged: (newSelection) {
                                  if (newSelection.isNotEmpty) {
                                    settingsNotifier.updateSkipStep(newSelection.first);
                                  }
                                },
                                showSelectedIcon: false,
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Long-press Speed (1.5x, 2.0x, 3.0x)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const _IconBadge(icon: Icons.speed_rounded),
                                const SizedBox(width: AppSpacing.md),
                                Text(
                                  'Long-press Speed',
                                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<double>(
                                segments: const [
                                  ButtonSegment<double>(value: 1.5, label: Text('1.5x')),
                                  ButtonSegment<double>(value: 2.0, label: Text('2.0x')),
                                  ButtonSegment<double>(value: 3.0, label: Text('3.0x')),
                                ],
                                selected: {settings.longPressSpeed},
                                onSelectionChanged: (newSelection) {
                                  if (newSelection.isNotEmpty) {
                                    settingsNotifier.updateLongPressSpeed(newSelection.first);
                                  }
                                },
                                showSelectedIcon: false,
                                style: const ButtonStyle(
                                  visualDensity: VisualDensity.compact,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Touch Gestures Toggle
                      _SettingsSwitchTile(
                        icon: Icons.touch_app_rounded,
                        title: 'Touch Gestures',
                        subtitle: 'Double-tap seek, hold speedup, brightness & volume drags',
                        value: settings.gesturesEnabled,
                        onChanged: (val) => settingsNotifier.setGesturesEnabled(val),
                      ),
                      const Divider(height: 1),

                      // Resume Behavior
                      _SettingsTile(
                        icon: Icons.restore_rounded,
                        title: 'Resume Behavior',
                        trailing: _DropdownPill<String>(
                          value: settings.resumeBehavior,
                          items: const ['always', 'never'],
                          displayLabel: (val) => val == 'always' ? 'Always resume' : 'Never resume',
                          onChanged: (val) {
                            if (val != null) settingsNotifier.updateResumeBehavior(val);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 3. STREAM SOURCES
                  _SectionHeader(title: l10n.streamSourceSection),
                  _SettingsCard(
                    children: [
                      _SettingsTile(
                        icon: Icons.cloud_queue_rounded,
                        title: l10n.manageSources,
                        onTap: () => context.push('/settings/sources'),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 4. DATA MANAGEMENT
                  const _SectionHeader(title: 'Data & Storage'),
                  _SettingsCard(
                    children: [
                      // Clear Cache
                      _SettingsTile(
                        icon: Icons.cached_rounded,
                        title: 'Clear Cache',
                        onTap: () => _handleClearCache(context, ref),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: AppRadius.pillBorder,
                            border: Border.all(color: AppColors.border, width: 0.8),
                          ),
                          child: const Text('Purge', style: AppText.meta),
                        ),
                      ),
                      const Divider(height: 1),

                      // Export Data (JSON)
                      _SettingsTile(
                        icon: Icons.file_upload_outlined,
                        title: 'Export Favorites & History',
                        onTap: () => _handleExportData(context, ref),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Divider(height: 1),

                      // Import Data (JSON)
                      _SettingsTile(
                        icon: Icons.file_download_outlined,
                        title: 'Import Favorites & History',
                        onTap: () => _handleImportData(context, ref),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 5. ABOUT
                  _SectionHeader(title: l10n.aboutSection),
                  _SettingsCard(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DEEN',
                                  style: AppText.sectionTitle.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Version 1.0.0',
                                  style: AppText.meta.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      const _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: 'App Version',
                        trailing: Text(
                          'v1.0.0 (Phase 6)',
                          style: AppText.meta,
                        ),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.dataset_outlined,
                        title: 'Data Credits',
                        trailing: Text(
                          'Bangumi · AniList',
                          overflow: TextOverflow.ellipsis,
                          style: AppText.meta.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.gavel_rounded,
                              size: 18,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'DEEN is an open-source metadata explorer and video player client. It does not host, upload, or own any video files or media content.',
                                style: AppText.meta.copyWith(
                                  color: AppColors.textMuted,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),

          // Bottom padding for floating navigation bar
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.floatingBarBottomPadding),
          ),
        ],
      ),
    );
  }

  void _handleClearCache(BuildContext context, WidgetRef ref) {
    final metadataRepo = ref.read(metadataRepositoryProvider);
    if (metadataRepo is MetadataRepositoryImpl) {
      metadataRepo.cache.clear();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text('Metadata cache purged successfully'),
      ),
    );
  }

  Future<void> _handleExportData(BuildContext context, WidgetRef ref) async {
    final followRepo = ref.read(followRepositoryProvider);
    final historyRepo = ref.read(playbackHistoryRepositoryProvider);

    final favorites = await followRepo.getFollowedList();
    final history = await historyRepo.getHistoryList();

    final backup = DataBackup(
      exportedAt: DateTime.now(),
      favorites: favorites,
      history: history,
    );

    final jsonStr = backup.toFormattedJson();

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
          title: const Text('Export Data (JSON)', style: AppText.sectionTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Exported ${favorites.length} favorites and ${history.length} history records.',
                    style: AppText.bodySecondary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.cardBorder,
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    constraints: const BoxConstraints(maxHeight: 220),
                    child: SingleChildScrollView(
                      child: Text(
                        jsonStr,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Close', style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonStr));
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.surfaceElevated,
                    content: Text('Backup JSON copied to clipboard'),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copy to Clipboard'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleImportData(BuildContext context, WidgetRef ref) async {
    final textController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
          title: const Text('Import Data (JSON)', style: AppText.sectionTitle),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Paste your backup JSON below to restore favorites and watch history:',
                  style: AppText.bodySecondary,
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: textController,
                  maxLines: 8,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    hintText: '{\n  "version": 1,\n  "favorites": [...],\n  "history": [...]\n}',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.cardBorder,
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppRadius.cardBorder,
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            FilledButton(
              onPressed: () async {
                final input = textController.text.trim();
                final backup = DataBackup.tryParse(input);

                if (backup == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: Color(0xFFFF453A),
                      content: Text('Invalid backup JSON format'),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogCtx).pop();

                final followRepo = ref.read(followRepositoryProvider);
                final historyRepo = ref.read(playbackHistoryRepositoryProvider);

                await followRepo.replaceFollowedList(backup.favorites);
                await historyRepo.replaceHistoryList(backup.history);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: AppColors.surfaceElevated,
                      content: Text(
                        'Restored ${backup.favorites.length} favorites & ${backup.history.length} history items',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Import'),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppText.sectionTitle.copyWith(fontSize: 16),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardBorder,
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;

  const _IconBadge({required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: theme.colorScheme.primary),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.cardBorder,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            _IconBadge(icon: icon),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _IconBadge(icon: icon),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppText.meta.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: primaryColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}


class _DropdownPill<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final String Function(T)? displayLabel;

  const _DropdownPill({
    required this.value,
    required this.items,
    required this.onChanged,
    this.displayLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: AppRadius.pillBorder,
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          dropdownColor: AppColors.surfaceElevated,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textSecondary, size: 18),
          style: AppText.meta.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          items: items.map((item) {
            final text = displayLabel != null ? displayLabel!(item) : item.toString();
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
