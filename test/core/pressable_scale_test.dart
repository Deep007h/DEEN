import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anime_stream/core/presentation/widgets/pressable_scale.dart';

void main() {
  testWidgets('PressableScale executes onTap callback when tapped', (tester) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PressableScale(
            onTap: () => tapped = true,
            child: const Text('Tap Me'),
          ),
        ),
      ),
    );

    expect(find.text('Tap Me'), findsOneWidget);
    await tester.tap(find.text('Tap Me'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });

  testWidgets('PressableScale passes child directly when no onTap or onLongPress', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PressableScale(
            child: Text('Non Interactive'),
          ),
        ),
      ),
    );

    expect(find.text('Non Interactive'), findsOneWidget);
  });
}
