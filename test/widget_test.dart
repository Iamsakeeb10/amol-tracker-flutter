import 'package:flutter_test/flutter_test.dart';

import 'package:amol_tracker_app/main.dart';

void main() {
  testWidgets('App boots with setup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Amol Tracker setup completed'), findsOneWidget);
  });
}
