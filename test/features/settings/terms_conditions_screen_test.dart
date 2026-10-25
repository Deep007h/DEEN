import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/features/settings/presentation/screens/terms_conditions_screen.dart';

void main() {
  group('TermsConditionsScreen Widget Tests', () {
    testWidgets('renders all terms sections and compliance headers', (tester) async {
      tester.view.physicalSize = const Size(1080, 8000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: TermsConditionsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('LEGAL & COMPLIANCE'), findsOneWidget);
      expect(find.text('DEEN Client v1.0'), findsOneWidget);

      // Section titles verification
      expect(find.text('Acceptance of Terms'), findsOneWidget);
      expect(find.text('Open-Source Client & Non-Hosting'), findsOneWidget);
      expect(find.text('Intellectual Property & Copyright'), findsOneWidget);
      expect(find.text('Third-Party Services & Monetization'), findsOneWidget);
      expect(find.text('Data Privacy & Local Storage'), findsOneWidget);

      // Confirmation button
      expect(find.text('I Understand & Accept'), findsOneWidget);
    });

    testWidgets('tap on acceptance button dismisses or handles click gracefully', (tester) async {
      tester.view.physicalSize = const Size(1080, 8000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TermsConditionsScreen(),
                    ),
                  );
                },
                child: const Text('Open Terms'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Terms'));
      await tester.pumpAndSettle();

      expect(find.byType(TermsConditionsScreen), findsOneWidget);

      final buttonFinder = find.text('I Understand & Accept');
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.byType(TermsConditionsScreen), findsNothing);
    });
  });
}
