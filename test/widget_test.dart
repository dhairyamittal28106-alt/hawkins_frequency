// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:hawkins_frequency/main.dart';

void main() {
  testWidgets('App starts and shows dimension switch screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HawkinsFrequencyApp());

    // Verify that the app shows the dimension switch screen
    expect(find.text('1985 MODE'), findsOneWidget);
  });
}
