import '../../../metadata/domain/models/anime_titles.dart';

/// App-wide user settings for Appearance, Playback, and Controls.
class AppSettings {
  // Appearance
  final int accentColorValue;
  final TitlePreference titlePreference;

  // Playback
  final String defaultQuality;
  final String defaultAudioLanguage;
  final String defaultSubtitleLanguage;
  final bool autoplayNext;
  final int skipStepSeconds;
  final double longPressSpeed;
  final bool gesturesEnabled;
  final String resumeBehavior; // 'always', 'prompt', 'never'

  const AppSettings({
    this.accentColorValue = 0xFFC6F16D, // AppColors.accent
    this.titlePreference = TitlePreference.english,
    this.defaultQuality = 'Auto',
    this.defaultAudioLanguage = 'Original',
    this.defaultSubtitleLanguage = 'English',
    this.autoplayNext = true,
    this.skipStepSeconds = 10,
    this.longPressSpeed = 2.0,
    this.gesturesEnabled = true,
    this.resumeBehavior = 'always',
  });

  Map<String, dynamic> toJson() {
    return {
      'accentColorValue': accentColorValue,
      'titlePreference': titlePreference.name,
      'defaultQuality': defaultQuality,
      'defaultAudioLanguage': defaultAudioLanguage,
      'defaultSubtitleLanguage': defaultSubtitleLanguage,
      'autoplayNext': autoplayNext,
      'skipStepSeconds': skipStepSeconds,
      'longPressSpeed': longPressSpeed,
      'gesturesEnabled': gesturesEnabled,
      'resumeBehavior': resumeBehavior,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    TitlePreference pref = TitlePreference.english;
    final prefStr = json['titlePreference'] as String?;
    if (prefStr != null) {
      for (final p in TitlePreference.values) {
        if (p.name == prefStr) {
          pref = p;
          break;
        }
      }
    }

    return AppSettings(
      accentColorValue: json['accentColorValue'] as int? ?? 0xFFC6F16D,
      titlePreference: pref,
      defaultQuality: json['defaultQuality'] as String? ?? 'Auto',
      defaultAudioLanguage: json['defaultAudioLanguage'] as String? ?? 'Original',
      defaultSubtitleLanguage: json['defaultSubtitleLanguage'] as String? ?? 'English',
      autoplayNext: json['autoplayNext'] as bool? ?? true,
      skipStepSeconds: json['skipStepSeconds'] as int? ?? 10,
      longPressSpeed: (json['longPressSpeed'] as num?)?.toDouble() ?? 2.0,
      gesturesEnabled: json['gesturesEnabled'] as bool? ?? true,
      resumeBehavior: json['resumeBehavior'] as String? ?? 'always',
    );
  }

  AppSettings copyWith({
    int? accentColorValue,
    TitlePreference? titlePreference,
    String? defaultQuality,
    String? defaultAudioLanguage,
    String? defaultSubtitleLanguage,
    bool? autoplayNext,
    int? skipStepSeconds,
    double? longPressSpeed,
    bool? gesturesEnabled,
    String? resumeBehavior,
  }) {
    return AppSettings(
      accentColorValue: accentColorValue ?? this.accentColorValue,
      titlePreference: titlePreference ?? this.titlePreference,
      defaultQuality: defaultQuality ?? this.defaultQuality,
      defaultAudioLanguage: defaultAudioLanguage ?? this.defaultAudioLanguage,
      defaultSubtitleLanguage: defaultSubtitleLanguage ?? this.defaultSubtitleLanguage,
      autoplayNext: autoplayNext ?? this.autoplayNext,
      skipStepSeconds: skipStepSeconds ?? this.skipStepSeconds,
      longPressSpeed: longPressSpeed ?? this.longPressSpeed,
      gesturesEnabled: gesturesEnabled ?? this.gesturesEnabled,
      resumeBehavior: resumeBehavior ?? this.resumeBehavior,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          accentColorValue == other.accentColorValue &&
          titlePreference == other.titlePreference &&
          defaultQuality == other.defaultQuality &&
          defaultAudioLanguage == other.defaultAudioLanguage &&
          defaultSubtitleLanguage == other.defaultSubtitleLanguage &&
          autoplayNext == other.autoplayNext &&
          skipStepSeconds == other.skipStepSeconds &&
          longPressSpeed == other.longPressSpeed &&
          gesturesEnabled == other.gesturesEnabled &&
          resumeBehavior == other.resumeBehavior;

  @override
  int get hashCode =>
      accentColorValue.hashCode ^
      titlePreference.hashCode ^
      defaultQuality.hashCode ^
      defaultAudioLanguage.hashCode ^
      defaultSubtitleLanguage.hashCode ^
      autoplayNext.hashCode ^
      skipStepSeconds.hashCode ^
      longPressSpeed.hashCode ^
      gesturesEnabled.hashCode ^
      resumeBehavior.hashCode;
}
