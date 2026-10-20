/// Quality option for a stream (e.g. 1080p, 720p, 480p, 360p, or Auto).
class QualityOption {
  final String label;
  final int? height;
  final int? width;
  final int? bandwidth;
  final String? url;
  final bool isAuto;

  const QualityOption({
    required this.label,
    this.height,
    this.width,
    this.bandwidth,
    this.url,
    this.isAuto = false,
  });

  factory QualityOption.auto({int? currentHeight}) => QualityOption(
        label: currentHeight != null ? 'Auto (${currentHeight}p)' : 'Auto',
        height: currentHeight,
        isAuto: true,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'height': height,
        'width': width,
        'bandwidth': bandwidth,
        'url': url,
        'isAuto': isAuto,
      };

  factory QualityOption.fromJson(Map<String, dynamic> json) => QualityOption(
        label: json['label'] as String? ?? 'Auto',
        height: json['height'] as int?,
        width: json['width'] as int?,
        bandwidth: json['bandwidth'] as int?,
        url: json['url'] as String?,
        isAuto: json['isAuto'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QualityOption &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          height == other.height &&
          isAuto == other.isAuto;

  @override
  int get hashCode => label.hashCode ^ height.hashCode ^ isAuto.hashCode;

  @override
  String toString() => 'QualityOption($label, ${height}p, bw: $bandwidth)';
}
