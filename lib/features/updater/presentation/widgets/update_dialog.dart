import 'package:flutter/material.dart';
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
    if (apkUri != null && await canLaunchUrl(apkUri)) {
      launched = await launchUrl(apkUri, mode: LaunchMode.externalApplication);
    }

    if (!launched && fallbackUri != null && await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
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
          borderRadius: BorderRadius.circular(AppRadius.modal),
          border: Border.all(color: AppColors.surfaceBright, width: 1.2),
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
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.accentBorder, width: 1),
                  ),
                  child: const Icon(
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
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.outlineVariant, width: 0.8),
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Text(
                  release.releaseNotes.isNotEmpty
                      ? release.releaseNotes
                      : 'Improvements, bug fixes, and performance updates.',
                  style: AppText.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Actions: Later vs Update
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      onDismiss?.call();
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.surfaceBright, width: 1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
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
