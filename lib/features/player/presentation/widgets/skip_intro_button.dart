import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_text.dart';

/// Discreet "+85s Skip Intro" chip appearing during the first 90s of playback.
class SkipIntroButton extends StatelessWidget {
  final VoidCallback onSkip;

  const SkipIntroButton({
    super.key,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSkip,
        borderRadius: AppRadius.pillBorder,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: AppRadius.pillBorder,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.fast_forward_rounded,
                size: 15,
                color: AppColors.accent,
              ),
              const SizedBox(width: 6),
              Text(
                'Skip Intro (+85s)',
                style: AppText.badgeText.copyWith(
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
