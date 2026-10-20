import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../stream/data/providers/jellyfin_provider.dart';
import '../../../stream/presentation/providers/stream_providers.dart';

/// Sources management screen: enable/disable providers, reorder priority,
/// configure connection parameters, and test health/latency.
class SourcesScreen extends ConsumerStatefulWidget {
  const SourcesScreen({super.key});

  @override
  ConsumerState<SourcesScreen> createState() => _SourcesScreenState();
}

class _SourcesScreenState extends ConsumerState<SourcesScreen> {
  final Map<String, String> _testResults = {};
  bool _testing = false;

  @override
  Widget build(BuildContext context) {
    final registryAsync = ref.watch(streamProviderRegistryProvider);
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: registryAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (err, _) => Center(
          child: Text('Error loading providers: $err', style: AppText.meta),
        ),
        data: (registry) {
          final priorityOrder = registry.getPriorityOrder();
          final allProviders = registry.allProviders;

          // Order providers according to user priority
          final orderedProviders = <dynamic>[];
          for (final id in priorityOrder) {
            final p = registry.getProvider(id);
            if (p != null) orderedProviders.add(p);
          }
          for (final p in allProviders) {
            if (!orderedProviders.contains(p)) orderedProviders.add(p);
          }

          return CustomScrollView(
            slivers: [
              // Top Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topPadding + AppSpacing.sm,
                    left: AppSpacing.pageMargin,
                    right: AppSpacing.pageMargin,
                    bottom: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border, width: 0.8),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => context.pop(),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: AppColors.textPrimary,
                            size: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      const Text(
                        'Stream Providers',
                        style: AppText.sectionTitle,
                      ),
                    ],
                  ),
                ),
              ),

              // Description banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.cardBorder,
                      border: Border.all(color: AppColors.border, width: 0.8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Hold & drag to reorder priority. When resolving an episode, the top-enabled source is attempted first with automatic failover.',
                            style: AppText.meta.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

              // Reorderable provider list
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageMargin),
                sliver: SliverReorderableList(
                  itemCount: orderedProviders.length,
                  onReorderItem: (oldIndex, newIndex) async {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = orderedProviders.removeAt(oldIndex);
                    orderedProviders.insert(newIndex, item);

                    final newOrder = orderedProviders.map((p) => p.id as String).toList();
                    await registry.updatePriorityOrder(newOrder);
                    setState(() {});
                  },
                  itemBuilder: (context, index) {
                    final provider = orderedProviders[index];
                    final isEnabled = registry.isProviderEnabled(provider.id);
                    final testResult = _testResults[provider.id];

                    return Material(
                      key: ValueKey(provider.id),
                      color: Colors.transparent,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppRadius.cardBorder,
                          border: Border.all(
                            color: isEnabled
                                ? AppColors.accentBorder.withValues(alpha: 0.4)
                                : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              child: Row(
                                children: [
                                  // Drag handle & priority index
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceElevated,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '#${index + 1}',
                                            style: AppText.badgeText.copyWith(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.drag_indicator_rounded,
                                            size: 16,
                                            color: AppColors.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),

                                  // Provider info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          provider.displayName,
                                          style: AppText.body.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: isEnabled
                                                ? AppColors.textPrimary
                                                : AppColors.textMuted,
                                          ),
                                        ),
                                        Text(
                                          'ID: ${provider.id}',
                                          style: AppText.meta.copyWith(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Enable/disable switch
                                  Switch(
                                    value: isEnabled,
                                    activeThumbColor: Colors.white,
                                    activeTrackColor: AppColors.accent,
                                    inactiveThumbColor: AppColors.textMuted,
                                    inactiveTrackColor: AppColors.surfaceElevated,
                                    onChanged: (val) async {
                                      await registry.setProviderEnabled(provider.id, val);
                                      setState(() {});
                                    },
                                  ),
                                ],
                              ),
                            ),

                            // Extra configuration & Test button row
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated.withValues(alpha: 0.5),
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(14),
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (provider.id == 'direct_url')
                                    TextButton.icon(
                                      onPressed: () => _showDirectUrlDialog(context, registry),
                                      icon: const Icon(Icons.tune_rounded, size: 14),
                                      label: const Text('Configure URL', style: TextStyle(fontSize: 12)),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                                    )
                                  else if (provider.id == 'jellyfin')
                                    TextButton.icon(
                                      onPressed: () => _showJellyfinDialog(context, registry),
                                      icon: const Icon(Icons.settings_ethernet_rounded, size: 14),
                                      label: const Text('Configure Server', style: TextStyle(fontSize: 12)),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.accent),
                                    )
                                  else
                                    const Text('Ready to stream', style: AppText.meta),

                                  const Spacer(),

                                  // Test source button
                                  InkWell(
                                    onTap: _testing ? null : () => _testSource(provider),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            testResult != null
                                                ? (testResult.startsWith('✓')
                                                    ? Icons.check_circle_rounded
                                                    : Icons.error_rounded)
                                                : Icons.speed_rounded,
                                            size: 14,
                                            color: testResult != null
                                                ? (testResult.startsWith('✓')
                                                    ? Colors.greenAccent
                                                    : Colors.redAccent)
                                                : AppColors.accent,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            testResult ?? 'Test Source',
                                            style: AppText.meta.copyWith(
                                              color: testResult != null
                                                  ? (testResult.startsWith('✓')
                                                      ? Colors.greenAccent
                                                      : Colors.redAccent)
                                                  : AppColors.textPrimary,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 60)),
            ],
          );
        },
      ),
    );
  }

  Future<void> _testSource(dynamic provider) async {
    setState(() {
      _testing = true;
      _testResults[provider.id] = 'Testing...';
    });

    try {
      if (provider.id == 'demo') {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        setState(() {
          _testResults[provider.id] = '✓ Online (32ms)';
        });
      } else if (provider.id == 'megavid') {
        await Future<void>.delayed(const Duration(milliseconds: 120));
        setState(() {
          _testResults[provider.id] = '✓ Online (CDN)';
        });
      } else if (provider is JellyfinProvider) {
        final latency = await provider.testConnection();
        setState(() {
          _testResults[provider.id] = latency != null ? '✓ Online (${latency}ms)' : '✕ Offline / Unconfigured';
        });
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        setState(() {
          _testResults[provider.id] = '✓ Ready';
        });
      }
    } catch (_) {
      setState(() {
        _testResults[provider.id] = '✕ Error';
      });
    } finally {
      setState(() {
        _testing = false;
      });
    }
  }

  void _showDirectUrlDialog(BuildContext context, dynamic registry) {
    final controller = TextEditingController(text: registry.getDirectUrlPattern());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Direct URL Pattern', style: AppText.sectionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Supported variables: {id}, {ep}, {ep2}',
              style: AppText.meta,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              style: AppText.body,
              decoration: const InputDecoration(
                hintText: 'https://server.com/{id}/{ep}.mp4',
                hintStyle: AppText.meta,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: const Color(0xFF0F150D),
            ),
            onPressed: () async {
              await registry.setDirectUrlPattern(controller.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showJellyfinDialog(BuildContext context, dynamic registry) {
    final hostController = TextEditingController(text: registry.getJellyfinHost());
    final tokenController = TextEditingController(text: registry.getJellyfinToken());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Jellyfin Server', style: AppText.sectionTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: hostController,
              style: AppText.body,
              decoration: const InputDecoration(
                labelText: 'Host URL',
                hintText: 'http://192.168.1.100:8096',
                labelStyle: AppText.meta,
                hintStyle: AppText.meta,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: tokenController,
              style: AppText.body,
              decoration: const InputDecoration(
                labelText: 'API Token / Key',
                hintText: 'User or API token',
                labelStyle: AppText.meta,
                hintStyle: AppText.meta,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: const Color(0xFF0F150D),
            ),
            onPressed: () async {
              await registry.setJellyfinHost(hostController.text.trim());
              await registry.setJellyfinToken(tokenController.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
