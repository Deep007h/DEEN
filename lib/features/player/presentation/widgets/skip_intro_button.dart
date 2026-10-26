import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/presentation/widgets/pressable_scale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
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
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSpacing.minTouchTarget,
      ),
      child: Center(
        child: PressableScale(
          targetScale: 0.94,
          curve: AppMotion.hyperOsSpring,
          onTap: onSkip,
          child: ClipRRect(
            borderRadius: AppRadius.pillBorder,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xD9101216),
                  borderRadius: AppRadius.pillBorder,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                    width: 0.9,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fast_forward_rounded,
                      size: 15,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Text(
                      'Skip Intro (+85s)',
                      style: AppText.badgeText.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
