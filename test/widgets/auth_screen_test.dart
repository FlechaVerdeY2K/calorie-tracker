import 'package:calorie_tracker/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpAuthScreen(
    WidgetTester tester, {
    Future<void> Function(String email, String password, bool isLogin)?
        onSubmit,
    Future<void> Function()? onGoogleSignIn,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AuthScreen(
          onSubmit: onSubmit,
          onGoogleSignIn: onGoogleSignIn,
        ),
      ),
    );
  }

  testWidgets('auth screen shows hero, form, and social actions',
      (tester) async {
    var googleTapped = 0;

    await pumpAuthScreen(
      tester,
      onGoogleSignIn: () async {
        googleTapped += 1;
      },
    );

    expect(find.text('Know what you eat. Own your goals.'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();

    expect(googleTapped, 1);
  });

  testWidgets('sign-up mode shows confirm password and blocks mismatch submit',
      (tester) async {
    var submitCalls = 0;

    await pumpAuthScreen(
      tester,
      onSubmit: (email, password, isLogin) async {
        submitCalls += 1;
      },
    );

    await tester.tap(find.text("Don't have an account? Create one"));
    await tester.pump();

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'hunter2');
    await tester.enterText(find.byType(TextField).at(2), 'different');

    await tester.tap(find.text('Create Account'));
    await tester.pump();

    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(submitCalls, 0);
  });

  testWidgets('password visibility toggle updates the password field',
      (tester) async {
    await pumpAuthScreen(tester);

    TextField passwordField() =>
        tester.widget<TextField>(find.byType(TextField).at(1));

    expect(passwordField().obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    expect(passwordField().obscureText, isFalse);
  });
}
