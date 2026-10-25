import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/presentation/widgets/pressable_scale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';

/// Full-featured, Material 3 + HyperOS 4 styled Terms & Conditions / Legal & Privacy Policy screen.
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: AppMotion.m3ScrollPhysics,
        slivers: [
          // 1. Header with back button and title
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding + AppSpacing.md,
                left: AppSpacing.pageMargin,
                right: AppSpacing.pageMargin,
                bottom: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 0.8),
                      ),
                      child: IconButton(
                        tooltip: 'Back',
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Terms & Conditions',
                          style: AppText.pageTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Legal, Content Policy & Privacy Disclosures',
                          style: AppText.meta.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 2. Main Content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Overview Hero Card
                _TermsHeroCard(),
                const SizedBox(height: AppSpacing.lg),

                // Section 1: Acceptance of Terms
                const _TermsSectionCard(
                  number: '01',
                  icon: Icons.handshake_rounded,
                  title: 'Acceptance of Terms',
                  content:
                      'By installing, downloading, or using DEEN (the "Application"), you expressly acknowledge and agree to be bound by these Terms of Service. If you do not agree with any part of these terms, you must immediately uninstall and discontinue using the application.',
                ),
                const SizedBox(height: AppSpacing.md),

                // Section 2: Non-Hosting & Client Nature
                const _TermsSectionCard(
                  number: '02',
                  icon: Icons.cloud_off_rounded,
                  title: 'Open-Source Client & Non-Hosting',
                  content:
                      'DEEN operates strictly as an open-source media player and metadata explorer client.\n\n'
                      '• DEEN DOES NOT host, upload, store, transcode, or transmit any video files, anime episodes, or audio media on any proprietary server.\n'
                      '• Video stream URLs are dynamically resolved on-demand through client-side scrapers querying publicly accessible third-party web services.\n'
                      '• DEEN maintains zero control over third-party servers, stream availability, latency, or content legality.',
                ),
                const SizedBox(height: AppSpacing.md),

                // Section 3: Intellectual Property & DMCA
                const _TermsSectionCard(
                  number: '03',
                  icon: Icons.copyright_rounded,
                  title: 'Intellectual Property & Copyright',
                  content:
                      'All anime titles, episode descriptions, posters, studio names, and audiovisual media are the intellectual property and copyright of their respective animation studios, creators, authors, and production committees.\n\n'
                      'DEEN claims no ownership or affiliation with any copyrighted anime material. If you represent a copyright holder and believe indexed endpoints infringe upon your rights, please submit a formal DMCA takedown request to the originating third-party hosting service.',
                ),
                const SizedBox(height: AppSpacing.md),

                // Section 4: Third-Party APIs & Monetization
                const _TermsSectionCard(
                  number: '04',
                  icon: Icons.ads_click_rounded,
                  title: 'Third-Party Services & Monetization',
                  content:
                      'DEEN integrates with publicly accessible community APIs (such as Bangumi and AniList) solely to provide metadata, cast lists, and seasonal rankings.\n\n'
                      'To offset the infrastructure costs of maintaining open-source builds, DEEN integrates privacy-compliant advertising services provided by Start.io. No personal data, tracking cookies, or contact information is collected or transmitted.',
                ),
                const SizedBox(height: AppSpacing.md),

                // Section 5: Data Privacy & Local Sovereignty
                const _TermsSectionCard(
                  number: '05',
                  icon: Icons.lock_outline_rounded,
                  title: 'Data Privacy & Local Storage',
                  content:
                      'Your privacy is fundamental to DEEN’s design philosophy:\n\n'
                      '• 100% Offline Storage: All bookmarks, favorite anime, watch history, playback timestamps, and audio/subtitle preferences are stored solely on your local device.\n'
                      '• No Accounts Required: No user accounts, passwords, or emails are ever requested.\n'
                      '• Data Portability: You may backup, export, or wipe your local records at any time from the Settings menu in standard JSON format.',
                ),
                const SizedBox(height: AppSpacing.md),

                // Section 6: User Responsibility & Compliance
                const _TermsSectionCard(
                  number: '06',
                  icon: Icons.shield_outlined,
                  title: 'User Lawful Responsibility',
                  content:
                      'As a user, you assume sole responsibility for ensuring that your consumption of multimedia streams complies with copyright, licensing, and broadcast regulations within your sovereign jurisdiction.',
                ),
                const SizedBox(height: AppSpacing.md),

                // Section 7: Limitation of Liability
                const _TermsSectionCard(
                  number: '07',
                  icon: Icons.gavel_rounded,
                  title: 'Disclaimer of Warranties & Liability',
                  content:
                      'The Application is provided strictly on an "AS IS" and "AS AVAILABLE" basis, without warranties of any kind, whether express, statutory, or implied.\n\n'
                      'The developers and contributors of DEEN disclaim all liability for any direct, indirect, incidental, or consequential damages resulting from the use or inability to use this application.',
                ),
                const SizedBox(height: AppSpacing.xl),

                // Confirmation / Acceptance Button
                PressableScale(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: AppColors.surfaceElevated,
                        content: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
                            SizedBox(width: 10),
                            Text('Terms of Service acknowledged'),
                          ],
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.of(context).maybePop();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.accentSoft,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'I Understand & Accept',
                        style: TextStyle(
                          color: Color(0xFF0B0E0B),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: bottomPadding + AppSpacing.xl),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.verified_user_rounded,
                  color: AppColors.accent,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'LEGAL & COMPLIANCE',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'DEEN Client v1.0',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This agreement outlines your rights, copyright notices, and our commitment to absolute data privacy. Please read these terms carefully.',
            style: AppText.bodySecondary.copyWith(
              height: 1.45,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                'Effective: October 2026',
                style: AppText.meta.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TermsSectionCard extends StatelessWidget {
  final String number;
  final IconData icon;
  final String title;
  final String content;

  const _TermsSectionCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.7),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.8,
                  ),
                ),
                child: Icon(icon, color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                number,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.25),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            content,
            style: AppText.bodySecondary.copyWith(
              color: const Color(0xFFC4C4CC),
              height: 1.5,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
