import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text.dart';
import '../../../stream/domain/resolvers/embed_stream_resolver.dart';

/// Modal dialog / bottom sheet allowing users to stream any MegaVid / KissKH embed URL
/// or quickly construct an embed URL using Anime ID, Episode number, and Audio toggle.
class EmbedStreamDialog extends StatefulWidget {
  final String? initialUrl;

  const EmbedStreamDialog({super.key, this.initialUrl});

  static Future<void> show(BuildContext context, {String? initialUrl}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EmbedStreamDialog(initialUrl: initialUrl),
    );
  }

  @override
  State<EmbedStreamDialog> createState() => _EmbedStreamDialogState();
}

class _EmbedStreamDialogState extends State<EmbedStreamDialog> {
  late final TextEditingController _urlController;
  late final TextEditingController _animeIdController;
  int _episodeNumber = 1;
  String _audio = 'sub'; // 'sub' or 'dub'
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialUrl ?? 'https://megavid.buzz/ani/178789/11/dub';
    _urlController = TextEditingController(text: initial);

    final info = EmbedStreamResolver.parseEmbedUrl(initial);
    _animeIdController = TextEditingController(text: info.animeId ?? '178789');
    _episodeNumber = info.episodeNumber;
    _audio = info.audio;
  }

  @override
  void dispose() {
    _urlController.dispose();
    _animeIdController.dispose();
    super.dispose();
  }

  void _syncFromUrl(String url) {
    final info = EmbedStreamResolver.parseEmbedUrl(url);
    if (info.isAnime && info.animeId != null) {
      setState(() {
        _animeIdController.text = info.animeId!;
        _episodeNumber = info.episodeNumber;
        _audio = info.audio;
        _errorMessage = null;
      });
    }
  }

  void _syncToUrl() {
    final animeId = _animeIdController.text.trim();
    if (animeId.isNotEmpty) {
      final generated = EmbedStreamResolver.buildEmbedUrl(
        animeId: animeId,
        episodeNumber: _episodeNumber,
        audio: _audio,
      );
      setState(() {
        _urlController.text = generated;
        _errorMessage = null;
      });
    }
  }

  Future<void> _handleStreamLaunch() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _errorMessage = 'Please enter an embed URL');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final info = EmbedStreamResolver.parseEmbedUrl(url);
      final animeId = int.tryParse(info.animeId ?? '') ?? 400602;
      final epNum = info.episodeNumber;

      if (!mounted) return;
      Navigator.of(context).pop();

      // Launch native video player with resolved anime ID, episode, and megavid provider
      context.push(
        '/player?animeId=$animeId&ep=$epNum&provider=megavid',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not resolve stream: $e';
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _urlController.text = data.text!.trim();
      _syncFromUrl(_urlController.text);
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _urlController.text.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied embed URL: ${_urlController.text.trim()}'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.surfaceElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.link_rounded,
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
                        'Stream from Embed URL',
                        style: AppText.sectionTitle.copyWith(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Uses test project background technique for native streaming',
                        style: AppText.meta.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white60),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Section 1: Embed URL Input Box
            Text(
              'EMBED URL',
              style: AppText.meta.copyWith(
                fontSize: 11,
                letterSpacing: 1.1,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: Colors.white12,
                ),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.play_circle_outline_rounded, color: AppColors.accent, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
                      decoration: const InputDecoration(
                        hintText: 'https://megavid.buzz/ani/178789/11/dub',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: _syncFromUrl,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.paste_rounded, color: AppColors.accent, size: 18),
                    tooltip: 'Paste from clipboard',
                    onPressed: _pasteFromClipboard,
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, color: Colors.white60, size: 18),
                    tooltip: 'Copy URL',
                    onPressed: _copyToClipboard,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Section 2: Quick Builder Stepper (Anime ID, Episode, Audio)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK BUILDER',
                    style: AppText.meta.copyWith(
                      fontSize: 11,
                      letterSpacing: 1.1,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      // Anime ID
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Anime ID', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Container(
                              height: 38,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              alignment: Alignment.center,
                              child: TextField(
                                controller: _animeIdController,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (_) => _syncToUrl(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Episode Stepper
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Episode', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.remove, color: Colors.white70, size: 16),
                                    onPressed: _episodeNumber > 1
                                        ? () {
                                            setState(() => _episodeNumber--);
                                            _syncToUrl();
                                          }
                                        : null,
                                  ),
                                  Text(
                                    '$_episodeNumber',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.add, color: Colors.white70, size: 16),
                                    onPressed: () {
                                      setState(() => _episodeNumber++);
                                      _syncToUrl();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Audio Dub/Sub Pill
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Audio', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setState(() => _audio = 'sub');
                                        _syncToUrl();
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _audio == 'sub' ? AppColors.accent : Colors.transparent,
                                          borderRadius: BorderRadius.circular(AppRadius.sm),
                                        ),
                                        child: Text(
                                          'SUB',
                                          style: TextStyle(
                                            color: _audio == 'sub' ? Colors.white : Colors.white60,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: InkWell(
                                      onTap: () {
                                        setState(() => _audio = 'dub');
                                        _syncToUrl();
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: _audio == 'dub' ? AppColors.accent : Colors.transparent,
                                          borderRadius: BorderRadius.circular(AppRadius.sm),
                                        ),
                                        child: Text(
                                          'DUB',
                                          style: TextStyle(
                                            color: _audio == 'dub' ? Colors.white : Colors.white60,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Action Buttons
            ElevatedButton(
              onPressed: _isLoading ? null : _handleStreamLaunch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Launch Native Player',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
