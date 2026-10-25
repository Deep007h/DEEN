import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../domain/models/app_release_info.dart';

/// Dark squircle OTA update dialog matching the DEEN obsidian/electric-lime design language.
class UpdateDialog extends StatelessWidget {
  final AppReleaseInfo release;
  final VoidCallback? onDismiss;

  const UpdateDialog({
    super.key,
    required this.release,
    this.onDismiss,
  });

  /// Static helper to display the update dialog.
  static Future<void> show(BuildContext context, AppReleaseInfo release) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) => UpdateDialog(release: release),
    );
  }

  Future<void> _handleUpdate(BuildContext context) async {
    final apkUri = Uri.tryParse(release.apkDownloadUrl);
    final fallbackUri = Uri.tryParse(release.htmlUrl);

    bool launched = false;
    if (apkUri != null) {
      try {
        launched = await launchUrl(apkUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    if (!launched && fallbackUri != null) {
      try {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }

    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sizeStr = release.formattedSize;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: AppRadius.squircleModalBorder,
          border: Border.all(color: AppColors.outlineVariant, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Icon + Title + Version pill
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: AppRadius.squircleInnerBorder,
                    border: Border.all(color: AppColors.accentBorder, width: 1),
                  ),
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    color: AppColors.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Available',
                        style: AppText.cardTitle.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              release.tagName,
                              style: AppText.meta.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          if (sizeStr != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              sizeStr,
                              style: AppText.meta.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Release Notes Box
            Text(
              "What's New",
              style: AppText.sectionTitle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 180),
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: AppRadius.squircleInnerBorder,
                border: Border.all(color: AppColors.outlineVariant, width: 0.8),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _FormattedReleaseNotes(
                  rawNotes: release.releaseNotes,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Actions: Later vs Update
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('dismissed_ota_tag', release.tagName);
                      } catch (_) {}
                      onDismiss?.call();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.outlineVariant, width: 1.0),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      'Later',
                      style: AppText.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleUpdate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    child: Text(
                      'Update',
                      style: AppText.labelMedium.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Cleanly formats markdown release notes:
/// - Converts headings (#, ##, ###) into bold section titles without hash symbols.
/// - Converts bullets (*, -, +) into stylized accent dot bullets.
/// - Converts **bold** and __bold__ tokens into FontWeight.w700.
/// - Strips backticks (`code` -> code).
/// - Filters out horizontal dividers (---, ***) and raw SHA-256 checksum hex digests.
class _FormattedReleaseNotes extends StatelessWidget {
  final String rawNotes;

  const _FormattedReleaseNotes({required this.rawNotes});

  @override
  Widget build(BuildContext context) {
    final trimmed = rawNotes.trim();
    if (trimmed.isEmpty) {
      return Text(
        'Improvements, bug fixes, and performance updates.',
        style: AppText.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.45,
          fontSize: 13,
        ),
      );
    }

    final lines = trimmed.split('\n');
    final widgets = <Widget>[];

    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // Filter out divider lines (---, ***, ===)
      if (RegExp(r'^[-*_]{3,}$').hasMatch(line)) continue;

      // Filter out SHA-256 / SHA-1 checksum hex digests (lines containing 32+ contiguous hex chars)
      if (RegExp(r'\b[a-fA-F0-9]{32,64}\b').hasMatch(line) &&
          (line.toLowerCase().contains('sha') ||
           line.toLowerCase().contains('checksum') ||
           line.toLowerCase().contains('.apk') ||
           line.startsWith('`'))) {
        continue;
      }

      // Filter out raw checksum table headers
      if (RegExp(r'^(#+\s*)?(sha-?256|checksums|hashes)', caseSensitive: false).hasMatch(line)) {
        continue;
      }

      // Markdown heading (#, ##, ###, etc.)
      final headerMatch = RegExp(r'^(#{1,6})\s*(.*)$').firstMatch(line);
      if (headerMatch != null) {
        final headingText = headerMatch.group(2)?.trim() ?? '';
        if (headingText.isNotEmpty) {
          if (widgets.isNotEmpty) {
            widgets.add(const SizedBox(height: 8));
          }
          widgets.add(
            Text(
              headingText,
              style: AppText.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          );
          widgets.add(const SizedBox(height: 4));
        }
        continue;
      }

      // Bullet items (*, -, +, 1.)
      final bulletMatch = RegExp(r'^(\*|-|\+|\d+\.)\s+(.*)$').firstMatch(line);
      if (bulletMatch != null) {
        final bulletText = bulletMatch.group(2)?.trim() ?? '';
        if (bulletText.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: _parseInlineSpans(bulletText),
                      ),
                      style: AppText.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        continue;
      }

      // Normal paragraph line
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text.rich(
            TextSpan(
              children: _parseInlineSpans(line),
            ),
            style: AppText.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      return Text(
        'Improvements, bug fixes, and performance updates.',
        style: AppText.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          height: 1.45,
          fontSize: 13,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  static List<InlineSpan> _parseInlineSpans(String rawText) {
    final cleaned = rawText.replaceAll('`', '');
    if (!cleaned.contains('**') && !cleaned.contains('__')) {
      return [TextSpan(text: cleaned)];
    }

    final spans = <InlineSpan>[];
    final boldRegex = RegExp(r'(\*\*|__)(.*?)\1');
    int lastIndex = 0;

    for (final match in boldRegex.allMatches(cleaned)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: cleaned.substring(lastIndex, match.start)));
      }
      final boldContent = match.group(2) ?? '';
      spans.add(TextSpan(
        text: boldContent,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ));
      lastIndex = match.end;
    }

    if (lastIndex < cleaned.length) {
      spans.add(TextSpan(text: cleaned.substring(lastIndex)));
    }

    return spans;
  }
}
