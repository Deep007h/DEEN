import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// Label for the Home bottom navigation tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// Label for the Explore bottom navigation tab
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get tabExplore;

  /// Label for the Library bottom navigation tab
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get tabLibrary;

  /// Label for the Following (追番) bottom navigation tab
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get tabFollowing;

  /// Label for the Recent watch history bottom navigation tab
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get tabRecent;

  /// Label for the Settings bottom navigation tab
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// Title displayed on the Home screen header
  ///
  /// In en, this message translates to:
  /// **'DEEN'**
  String get homeTitle;

  /// Section header for popular/trending anime
  ///
  /// In en, this message translates to:
  /// **'Popular Anime'**
  String get homePopularHeader;

  /// Prompt on Home screen encouraging user to search
  ///
  /// In en, this message translates to:
  /// **'Search for an anime to get started'**
  String get homeEmptySearchPrompt;

  /// Subtext on Home screen under the search prompt
  ///
  /// In en, this message translates to:
  /// **'Explore thousands of titles, track what you love, and enjoy smooth playback.'**
  String get homeEmptySearchSubtext;

  /// Label for search action button
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchAction;

  /// Top bar title on search screen
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// Large header on search page
  ///
  /// In en, this message translates to:
  /// **'Anime Search'**
  String get bangumiSearchTitle;

  /// Subtitle explaining how search works
  ///
  /// In en, this message translates to:
  /// **'Filter anime by keyword and sorting, then pick available stream sources in detail.'**
  String get searchInstruction;

  /// Placeholder hint inside search input field
  ///
  /// In en, this message translates to:
  /// **'Search by anime title...'**
  String get searchHint;

  /// Sort/filter option for keyword match
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get filterMatch;

  /// Sort/filter option for popularity
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get filterPopularity;

  /// Sort/filter option for rating
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get filterRating;

  /// Tag filter label
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagFilter;

  /// Play episode button
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playAction;

  /// Follow/Bookmark anime button
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get followAction;

  /// Already followed anime state
  ///
  /// In en, this message translates to:
  /// **'Followed'**
  String get followedAction;

  /// Title for the episodes list section
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get episodesTitle;

  /// Title for tags section
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsTitle;

  /// Title displayed on Following screen header
  ///
  /// In en, this message translates to:
  /// **'Following'**
  String get followingTitle;

  /// Empty state title on Following screen
  ///
  /// In en, this message translates to:
  /// **'No followed anime yet'**
  String get followingEmpty;

  /// Empty state description on Following screen
  ///
  /// In en, this message translates to:
  /// **'Bookmark your favorite anime to receive updates on new episodes.'**
  String get followingEmptyDesc;

  /// Title displayed on Recent watch history header
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentTitle;

  /// Empty state title on Recent screen
  ///
  /// In en, this message translates to:
  /// **'No watch history'**
  String get recentEmpty;

  /// Empty state description on Recent screen
  ///
  /// In en, this message translates to:
  /// **'Anime you\'ve watched will show up here so you can easily pick up where you left off.'**
  String get recentEmptyDesc;

  /// Title displayed on Settings screen header
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Appearance section in settings
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceSection;

  /// Theme option title
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get themeOption;

  /// Stream sources section title in settings
  ///
  /// In en, this message translates to:
  /// **'Stream Sources'**
  String get streamSourceSection;

  /// Manage stream providers option
  ///
  /// In en, this message translates to:
  /// **'Manage Providers'**
  String get manageSources;

  /// About section in settings
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutSection;

  /// App version label
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get appVersion;

  /// Retry action button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Failed to load content'**
  String get errorLoading;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
