import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anime_stream/features/updater/domain/models/app_release_info.dart';
import 'package:anime_stream/features/updater/presentation/widgets/update_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UpdateDialog Widget Tests', () {
    const testRelease = AppReleaseInfo(
      tagName: 'v1.0.1',
      title: 'DEEN v1.0.1 Update',
      releaseNotes: 'Fixed animations and added OTA system.',
      htmlUrl: 'https://github.com/Deep007h/DEEN/releases/tag/v1.0.1',
      apkDownloadUrl: 'https://github.com/Deep007h/DEEN/releases/download/v1.0.1/app-arm64-v8a-release.apk',
      apkSize: 34 * 1024 * 1024,
    );

    testWidgets('Renders update dialog with version, release notes, Later and Update buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateDialog(release: testRelease),
          ),
        ),
      );

      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('v1.0.1'), findsOneWidget);
      expect(find.text('34.0 MB'), findsOneWidget);
      expect(find.text("What's New"), findsOneWidget);
      expect(find.text('Fixed animations and added OTA system.'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('Tapping Later triggers onDismiss and persists dismissed tag', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (_) => UpdateDialog(
                      release: testRelease,
                      onDismiss: () {
                        dismissed = true;
                      },
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Update Available'), findsOneWidget);

      // Tap Later
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
      expect(find.text('Update Available'), findsNothing);

      // Verify tag persisted in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('dismissed_ota_tag'), equals('v1.0.1'));
    });

    testWidgets('Cleanly formats raw markdown: strips #, *, **, and hides SHA checksums', (tester) async {
      const rawMarkdownRelease = AppReleaseInfo(
        tagName: 'v2.0.0',
        title: 'DEEN v2.0.0',
        releaseNotes: '''
## What's Changed
* **Top Bar**: Auto-hides on downward scroll
* **120Hz**: Ultra-smooth detail page transitions
- Cleaned markdown tokens in dialog
### Checksums
`d3b07384d113edec49eaa6238ad5ff00fc7ff00c3b88965b263b6cf90e44ffc7` DEEN-v2-arm64-v8a.apk
''',
        htmlUrl: 'https://github.com/Deep007h/DEEN/releases/tag/v2.0.0',
        apkDownloadUrl: 'https://github.com/Deep007h/DEEN/releases/download/v2.0.0/DEEN-v2-arm64-v8a.apk',
        apkSize: 28 * 1024 * 1024,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UpdateDialog(release: rawMarkdownRelease),
          ),
        ),
      );

      // Raw '#' tokens should NOT be present in any rendered Text widget
      expect(find.text("## What's Changed"), findsNothing);
      expect(find.text("### Checksums"), findsNothing);

      // Formatted header without '##' should be present
      expect(find.text("What's Changed"), findsOneWidget);

      // Check bullet items are rendered with text (not raw '*')
      expect(find.textContaining('Auto-hides on downward scroll'), findsOneWidget);
      expect(find.textContaining('Ultra-smooth detail page transitions'), findsOneWidget);
      expect(find.textContaining('Cleaned markdown tokens in dialog'), findsOneWidget);

      // SHA-256 hash should be completely filtered out
      expect(find.textContaining('d3b07384d113edec49eaa6238ad5ff00fc7ff00c3b88965b263b6cf90e44ffc7'), findsNothing);
    });
  });
}
