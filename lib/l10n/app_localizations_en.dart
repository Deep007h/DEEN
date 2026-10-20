// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabHome => 'Home';

  @override
  String get tabFollowing => 'Following';

  @override
  String get tabRecent => 'Recent';

  @override
  String get tabSettings => 'Settings';

  @override
  String get homeTitle => 'DEEN';

  @override
  String get homePopularHeader => 'Popular Anime';

  @override
  String get homeEmptySearchPrompt => 'Search for an anime to get started';

  @override
  String get homeEmptySearchSubtext =>
      'Explore thousands of titles, track what you love, and enjoy smooth playback.';

  @override
  String get searchAction => 'Search';

  @override
  String get searchTitle => 'Search';

  @override
  String get bangumiSearchTitle => 'Anime Search';

  @override
  String get searchInstruction =>
      'Filter anime by keyword and sorting, then pick available stream sources in detail.';

  @override
  String get searchHint => 'Search by anime title...';

  @override
  String get filterMatch => 'Match';

  @override
  String get filterPopularity => 'Popular';

  @override
  String get filterRating => 'Rating';

  @override
  String get tagFilter => 'Tags';

  @override
  String get playAction => 'Play';

  @override
  String get followAction => 'Follow';

  @override
  String get followedAction => 'Followed';

  @override
  String get episodesTitle => 'Episodes';

  @override
  String get tagsTitle => 'Tags';

  @override
  String get followingTitle => 'Following';

  @override
  String get followingEmpty => 'No followed anime yet';

  @override
  String get followingEmptyDesc =>
      'Bookmark your favorite anime to receive updates on new episodes.';

  @override
  String get recentTitle => 'Recent';

  @override
  String get recentEmpty => 'No watch history';

  @override
  String get recentEmptyDesc =>
      'Anime you\'ve watched will show up here so you can easily pick up where you left off.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themeOption => 'Dark Theme';

  @override
  String get streamSourceSection => 'Stream Sources';

  @override
  String get manageSources => 'Manage Providers';

  @override
  String get aboutSection => 'About';

  @override
  String get appVersion => 'Version 1.0.0';

  @override
  String get retry => 'Retry';

  @override
  String get errorLoading => 'Failed to load content';
}
