// Basic smoke test for the real app entry point (the scaffold-generated
// counter-app test that used to live here referenced a non-existent `MyApp`
// class and never matched this project).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:micraa_flutter/main.dart';
import 'package:micraa_flutter/providers/app_state.dart';

void main() {
  testWidgets('app boots without crashing and settles on a screen', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: const MicraaApp(),
      ),
    );

    // While the initial login check resolves, a MaterialApp must already be
    // showing (no crash on boot).
    expect(find.byType(MaterialApp), findsOneWidget);

    // Not pumpAndSettle(): the initial loading state renders an indeterminate
    // CircularProgressIndicator, which animates forever and would time out
    // "settle". A handful of timed pumps is enough for the login-check
    // Future (backed by flutter_secure_storage, unavailable in this widget
    // test) to resolve one way or another.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Whatever the login-check outcome, the app must land on some scaffold.
    expect(find.byType(Scaffold), findsWidgets);
  });
}
