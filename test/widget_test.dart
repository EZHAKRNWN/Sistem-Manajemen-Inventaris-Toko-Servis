import 'package:flutter_test/flutter_test.dart';
import 'package:smartfix_mobile/main.dart';

void main() {
  testWidgets('Renders LoginScreen when user is not logged in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartFixApp(isLoggedIn: false));

    expect(find.text('SmartFix Mobile'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
