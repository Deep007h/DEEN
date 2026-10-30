import '../../../metadata/domain/models/anime_titles.dart';

/// App-wide user settings for Appearance, Playback, and Controls.
class AppSettings {
  // Appearance
  final int accentColorValue;
  final TitlePreference titlePreference;

  // Playback
  final String defaultQuality;
  final String defaultAudioLanguage;
  final String secondaryAudioLanguage;
  final String defaultSubtitleLanguage;
  final bool autoplayNext;
  final int skipStepSeconds;
  final double longPressSpeed;
  final bool gesturesEnabled;
  final String resumeBehavior; // 'always', 'prompt', 'never'
  final bool longPressMigrated;

  const AppSettings({
    this.accentColorValue = 0xFFB5F237, // AppColors.defaultAccentValue
    this.titlePreference = TitlePreference.english,
    this.defaultQuality = 'Auto',
    this.defaultAudioLanguage = 'Original',
    this.secondaryAudioLanguage = 'English',
    this.defaultSubtitleLanguage = 'English',
    this.autoplayNext = true,
    this.skipStepSeconds = 10,
    this.longPressSpeed = 1.5,
    this.gesturesEnabled = true,
    this.resumeBehavior = 'always',
    this.longPressMigrated = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'accentColorValue': accentColorValue,
      'titlePreference': titlePreference.name,
      'defaultQuality': defaultQuality,
      'defaultAudioLanguage': defaultAudioLanguage,
      'secondaryAudioLanguage': secondaryAudioLanguage,
      'defaultSubtitleLanguage': defaultSubtitleLanguage,
      'autoplayNext': autoplayNext,
      'skipStepSeconds': skipStepSeconds,
      'longPressSpeed': longPressSpeed,
      'gesturesEnabled': gesturesEnabled,
      'resumeBehavior': resumeBehavior,
      'longPressMigrated': true,
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

    final rawLongPressSpeed = (json['longPressSpeed'] as num?)?.toDouble();
    final bool longPressMigrated = json['longPressMigrated'] as bool? ?? false;
    final double longPressSpeed;
    if (!longPressMigrated && (rawLongPressSpeed == null || rawLongPressSpeed == 2.0)) {
      // Legacy versions defaulted to 2.0. Automatically migrate existing installs to 1.5.
      longPressSpeed = 1.5;
    } else {
      longPressSpeed = rawLongPressSpeed ?? 1.5;
    }

    final rawAccent = json['accentColorValue'] as int?;
    final int accentColorValue = (rawAccent == null || rawAccent == 0xFFC6F16D) ? 0xFFB5F237 : rawAccent;

    return AppSettings(
      accentColorValue: accentColorValue,
      titlePreference: pref,
      defaultQuality: json['defaultQuality'] as String? ?? 'Auto',
      defaultAudioLanguage: json['defaultAudioLanguage'] as String? ?? 'Original',
      secondaryAudioLanguage: json['secondaryAudioLanguage'] as String? ?? 'English',
      defaultSubtitleLanguage: json['defaultSubtitleLanguage'] as String? ?? 'English',
      autoplayNext: json['autoplayNext'] as bool? ?? true,
      skipStepSeconds: json['skipStepSeconds'] as int? ?? 10,
      longPressSpeed: longPressSpeed,
      gesturesEnabled: json['gesturesEnabled'] as bool? ?? true,
      resumeBehavior: json['resumeBehavior'] as String? ?? 'always',
      longPressMigrated: true,
    );
  }

  AppSettings copyWith({
    int? accentColorValue,
    TitlePreference? titlePreference,
    String? defaultQuality,
    String? defaultAudioLanguage,
    String? secondaryAudioLanguage,
    String? defaultSubtitleLanguage,
    bool? autoplayNext,
    int? skipStepSeconds,
    double? longPressSpeed,
    bool? gesturesEnabled,
    String? resumeBehavior,
    bool? longPressMigrated,
  }) {
    return AppSettings(
      accentColorValue: accentColorValue ?? this.accentColorValue,
      titlePreference: titlePreference ?? this.titlePreference,
      defaultQuality: defaultQuality ?? this.defaultQuality,
      defaultAudioLanguage: defaultAudioLanguage ?? this.defaultAudioLanguage,
      secondaryAudioLanguage: secondaryAudioLanguage ?? this.secondaryAudioLanguage,
      defaultSubtitleLanguage: defaultSubtitleLanguage ?? this.defaultSubtitleLanguage,
      autoplayNext: autoplayNext ?? this.autoplayNext,
      skipStepSeconds: skipStepSeconds ?? this.skipStepSeconds,
      longPressSpeed: longPressSpeed ?? this.longPressSpeed,
      gesturesEnabled: gesturesEnabled ?? this.gesturesEnabled,
      resumeBehavior: resumeBehavior ?? this.resumeBehavior,
      longPressMigrated: longPressMigrated ?? this.longPressMigrated,
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
          secondaryAudioLanguage == other.secondaryAudioLanguage &&
          defaultSubtitleLanguage == other.defaultSubtitleLanguage &&
          autoplayNext == other.autoplayNext &&
          skipStepSeconds == other.skipStepSeconds &&
          longPressSpeed == other.longPressSpeed &&
          gesturesEnabled == other.gesturesEnabled &&
          resumeBehavior == other.resumeBehavior &&
          longPressMigrated == other.longPressMigrated;

  @override
  int get hashCode =>
      accentColorValue.hashCode ^
      titlePreference.hashCode ^
      defaultQuality.hashCode ^
      defaultAudioLanguage.hashCode ^
      secondaryAudioLanguage.hashCode ^
      defaultSubtitleLanguage.hashCode ^
      autoplayNext.hashCode ^
      skipStepSeconds.hashCode ^
      longPressSpeed.hashCode ^
      gesturesEnabled.hashCode ^
      resumeBehavior.hashCode ^
      longPressMigrated.hashCode;
}
