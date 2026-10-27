






import 'package:flutter_test/flutter_test.dart';

import 'package:hawkins_frequency/main.dart';

void main() {
  testWidgets('App starts and shows dimension switch screen', (WidgetTester tester) async {
    
    await tester.pumpWidget(const HawkinsFrequencyApp());

    
    expect(find.text('1985 MODE'), findsOneWidget);
  });
}
