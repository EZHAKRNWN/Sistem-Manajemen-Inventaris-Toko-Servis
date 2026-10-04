// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:smartfix_mobile/main.dart';

void main() {
  testWidgets('Renders MainLayout when user is logged in', (WidgetTester tester) async {
    // Build our app with active session
    await tester.pumpWidget(const SmartFixApp(isLoggedIn: true));

    // Verify navigation bar destinations exist in MainLayout
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Tools'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Add Part'), findsOneWidget);
  });

  testWidgets('Renders LoginScreen when user is not logged in', (WidgetTester tester) async {
    // Build app without session
    await tester.pumpWidget(const SmartFixApp(isLoggedIn: false));

    // Verify login screen elements are rendered
    expect(find.text('SmartFix Mobile'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Quick Biometric Sign-In'), findsOneWidget);
  });
}
