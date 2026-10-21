import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:anime_stream/l10n/app_localizations.dart';
import 'package:anime_stream/features/settings/presentation/screens/settings_screen.dart';
import 'package:anime_stream/features/settings/data/repositories/app_settings_repository.dart';
import 'package:anime_stream/features/metadata/domain/models/anime_titles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
  });

  group('SettingsScreen Tests', () {
    testWidgets('Renders all sections and options properly', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Section titles
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Playback'), findsOneWidget);
      expect(find.text('Stream Sources'), findsOneWidget);
      expect(find.text('Data & Storage'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);

      // Playback options
      expect(find.text('Default Quality'), findsOneWidget);
      expect(find.text('Default Audio'), findsOneWidget);
      expect(find.text('Default Subtitles'), findsOneWidget);
      expect(find.text('Autoplay Next Episode'), findsOneWidget);
      expect(find.text('Skip Step'), findsOneWidget);
      expect(find.text('Long-press Speed'), findsOneWidget);
      expect(find.text('Touch Gestures'), findsOneWidget);
      expect(find.text('Resume Behavior'), findsOneWidget);

      // About
      expect(find.text('App Version'), findsOneWidget);
      expect(find.text('v1 (1.0.0)'), findsOneWidget);
      expect(find.text('Check for Updates'), findsOneWidget);
    });

    testWidgets('Changing title preference updates state', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      late WidgetRef refCapture;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Consumer(
              builder: (context, ref, child) {
                refCapture = ref;
                return const SettingsScreen();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default is English
      expect(refCapture.read(appSettingsProvider).titlePreference, TitlePreference.english);

      // Tap Original segment (first occurrence, inside Title Language)
      await tester.tap(find.text('Original').first);
      await tester.pumpAndSettle();

      expect(refCapture.read(appSettingsProvider).titlePreference, TitlePreference.original);

      // Tap Localized
      await tester.tap(find.text('Localized'));
      await tester.pumpAndSettle();

      expect(refCapture.read(appSettingsProvider).titlePreference, TitlePreference.localized);
    });

    testWidgets('Changing skip step updates state', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      late WidgetRef refCapture;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Consumer(
              builder: (context, ref, child) {
                refCapture = ref;
                return const SettingsScreen();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(refCapture.read(appSettingsProvider).skipStepSeconds, 10);

      // Tap 15s
      await tester.tap(find.text('15s'));
      await tester.pumpAndSettle();

      expect(refCapture.read(appSettingsProvider).skipStepSeconds, 15);

      // Tap 30s
      await tester.tap(find.text('30s'));
      await tester.pumpAndSettle();

      expect(refCapture.read(appSettingsProvider).skipStepSeconds, 30);
    });

    testWidgets('Clear cache button shows feedback snackbar', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SettingsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Clear Cache
      await tester.tap(find.text('Clear Cache'));
      await tester.pumpAndSettle();

      expect(find.text('Metadata cache purged successfully'), findsOneWidget);
    });

    testWidgets('Export data button opens export dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SettingsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Export Favorites & History
      await tester.tap(find.text('Export Favorites & History'));
      await tester.pumpAndSettle();

      // Verify dialog is shown
      expect(find.text('Export Data (JSON)'), findsOneWidget);
      expect(find.text('Copy to Clipboard'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Export Data (JSON)'), findsNothing);
    });

    testWidgets('Import data flow shows confirmation dialog and cancels or proceeds', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SettingsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Import Favorites & History
      await tester.tap(find.text('Import Favorites & History'));
      await tester.pumpAndSettle();

      expect(find.text('Import Data (JSON)'), findsOneWidget);

      // Enter valid JSON
      await tester.enterText(
        find.byType(TextField),
        '{"version": 1, "exportedAt": "2026-10-21T00:00:00.000", "favorites": [], "history": []}',
      );
      await tester.pumpAndSettle();

      // Tap Import button in first dialog
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Import Data'), findsOneWidget);
      expect(
        find.text('This will replace your current 0 favorites and 0 history records. Continue?'),
        findsOneWidget,
      );

      // Cancel should close confirmation dialog without restoring
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Import Data'), findsNothing);
      expect(find.text('Restored 0 favorites & 0 history items'), findsNothing);

      // Tap Import again and confirm this time
      await tester.tap(find.text('Import Favorites & History'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField),
        '{"version": 1, "exportedAt": "2026-10-21T00:00:00.000", "favorites": [], "history": []}',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();

      expect(find.text('Import Data'), findsOneWidget);

      // Tap Import in confirmation dialog
      await tester.tap(find.widgetWithText(FilledButton, 'Import'));
      await tester.pumpAndSettle();

      expect(find.text('Import Data'), findsNothing);
      expect(find.text('Restored 0 favorites & 0 history items'), findsOneWidget);
    });
  });
}
