import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:remindmd/screens/auth/login_screen.dart';

void main() {
  setUpAll(() {
    // Avoid network font fetches during tests.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('LoginScreen shows RemindMD branding and email/password fields', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    expect(find.text('RemindMD'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
