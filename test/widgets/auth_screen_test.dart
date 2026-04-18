import 'package:calorie_tracker/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:calorie_tracker/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class FakeAuthService extends ChangeNotifier implements AuthService {
  var signInCalls = 0;
  var signUpCalls = 0;
  var googleSignInCalls = 0;

  @override
  User? get currentUser => null;

  @override
  Future<void> signIn(String email, String password) async {
    signInCalls += 1;
  }

  @override
  Future<void> signUp(String email, String password) async {
    signUpCalls += 1;
  }

  @override
  Future<void> signInWithGoogle() async {
    googleSignInCalls += 1;
  }

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> signOut() async {}
}

void main() {
  Future<FakeAuthService> pumpAuthScreen(WidgetTester tester) async {
    final auth = FakeAuthService();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthService>.value(
        value: auth,
        child: const MaterialApp(
          home: AuthScreen(),
        ),
      ),
    );

    return auth;
  }

  testWidgets('auth screen shows hero, form, and social actions',
      (tester) async {
    final auth = await pumpAuthScreen(tester);

    expect(find.text('Know what you eat. Own your goals.'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();

    expect(auth.googleSignInCalls, 1);
  });

  testWidgets('sign-up mode shows confirm password and blocks mismatch submit',
      (tester) async {
    final auth = await pumpAuthScreen(tester);

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
    expect(auth.signUpCalls, 0);
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
