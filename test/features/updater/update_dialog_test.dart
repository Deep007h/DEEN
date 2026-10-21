import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/updater/domain/models/app_release_info.dart';
import 'package:anime_stream/features/updater/presentation/widgets/update_dialog.dart';

void main() {
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

    testWidgets('Tapping Later triggers onDismiss and dismisses dialog', (tester) async {
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
    });
  });
}
