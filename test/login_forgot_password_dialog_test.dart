import 'package:covoit_campus/screens/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('forgot-password dialog can open, close, and reopen safely', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

    final forgotButton = find.text('Mot de passe oublié ?');
    await tester.ensureVisible(forgotButton);
    await tester.tap(forgotButton);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Adresse e-mail'), findsOneWidget);

    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(forgotButton);
    await tester.tap(forgotButton);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      'person@example.tn',
    );
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
