import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:micraa_flutter/screens/auth_screen.dart';

/// Ticket-001: "Do not expose a role selector in Flutter registration" /
/// "registration does not show a role selector".
void main() {
  testWidgets('registration form shows no role selector', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(onAuthSuccess: (_) {}),
    ));

    // Switch from the default login mode to the registration form.
    final toggle = find.text('ليس لديك حساب؟ أنشئ حسابًا جديدًا');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pump();

    expect(find.text('إنشاء حساب'), findsWidgets);
    // No widget lets the user pick TEACHER/STUDENT/ADMIN at registration.
    expect(find.byType(DropdownButton<String>), findsNothing);
    expect(find.text('معلم'), findsNothing);
    expect(find.text('طالب'), findsNothing);
  });

  testWidgets('login form (default) also has no role selector', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(onAuthSuccess: (_) {}),
    ));

    expect(find.byType(DropdownButton<String>), findsNothing);
  });

  testWidgets('login form offers Google sign-in', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: AuthScreen(onAuthSuccess: (_) {}),
    ));

    expect(find.text('المتابعة باستخدام Google'), findsOneWidget);
  });
}
