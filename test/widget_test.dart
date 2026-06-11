import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slavia_mobile/screens/banned_screen.dart';

void main() {
  testWidgets('Banned screen shows logout action', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BannedScreen(
          reason: 'Zaległość ze składką',
          onLogout: () {},
        ),
      ),
    );

    expect(find.text('Konto zbanowane'), findsOneWidget);
    expect(find.textContaining('Zaległość'), findsOneWidget);
    expect(find.text('Wyloguj'), findsOneWidget);
  });
}
