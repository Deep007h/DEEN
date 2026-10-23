import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/logging/error_logger.dart';
import 'core/router/app_router.dart';
import 'core/services/ad_service.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/data/repositories/app_settings_repository.dart';
import 'l10n/app_localizations.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorLogger.initialize();

  // Initialize SharedPreferences on launch so user settings and data persist synchronously
  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('Failed to load SharedPreferences on start: $e');
  }

  // Initialize Start.io AdService early so first interstitial is cached
  final testMode = prefs?.getBool('test_ads_enabled') ?? true;
  try {
    await AdService.instance.initialize(testMode: testMode);
  } catch (e) {
    debugPrint('AdService startup initialization error: $e');
  }

  // Set system UI styling for edge-to-edge dark theme
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        if (prefs != null) sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const DeenApp(),
    ),
  );
}

class DeenApp extends ConsumerWidget {
  const DeenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = ref.watch(accentColorProvider);

    return MaterialApp.router(
      title: 'DEEN',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: AppTheme.buildDarkTheme(accentColor),
      darkTheme: AppTheme.buildDarkTheme(accentColor),
      routerConfig: appRouter,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}

/// Backward compatibility alias for tests
typedef AnimeStreamApp = DeenApp;
