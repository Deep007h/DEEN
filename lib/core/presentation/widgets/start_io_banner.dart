import 'package:flutter/material.dart';

/// Ad-free placeholder banner widget that renders nothing.
class StartIoBannerWidget extends StatelessWidget {
  final EdgeInsetsGeometry margin;
  final bool showLabel;

  const StartIoBannerWidget({
    super.key,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
