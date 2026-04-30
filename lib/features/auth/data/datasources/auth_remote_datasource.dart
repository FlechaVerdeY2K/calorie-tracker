import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/error/exceptions.dart' as core_exceptions;
import '../../../../core/supabase/supabase_client.dart';
import '../models/auth_user_model.dart';

/// Remote data source for authentication operations using Supabase
@lazySingleton
class AuthRemoteDataSource {
  final supabase.SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  AuthRemoteDataSource()
      : _supabase = SupabaseClientService.client,
        _googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

  /// Sign in with email and password
  Future<AuthUserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const core_exceptions.AuthException('Sign in failed: No user returned');
      }

      return AuthUserModel.fromSupabaseUser(response.user!);
    } on supabase.AuthException catch (e) {
      throw core_exceptions.AuthException(e.message);
    } catch (e) {
      throw core_exceptions.ServerException(e.toString());
    }
  }

  /// Sign up with email and password
  Future<AuthUserModel> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const core_exceptions.AuthException('Sign up failed: No user returned');
      }

      return AuthUserModel.fromSupabaseUser(response.user!);
    } on supabase.AuthException catch (e) {
      throw core_exceptions.AuthException(e.message);
    } catch (e) {
      throw core_exceptions.ServerException(e.toString());
    }
  }

  /// Sign in with Google
  Future<AuthUserModel> signInWithGoogle() async {
    try {
      // Sign in with Google to get ID token
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const core_exceptions.AuthException('Google sign in cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw const core_exceptions.AuthException('No ID token from Google');
      }

      // Sign in to Supabase with Google ID token
      final response = await _supabase.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        throw const core_exceptions.AuthException('Google sign in failed: No user returned');
      }

      return AuthUserModel.fromSupabaseUser(response.user!);
    } on supabase.AuthException catch (e) {
      throw core_exceptions.AuthException(e.message);
    } catch (e) {
      throw core_exceptions.ServerException(e.toString());
    }
  }

  /// Sign in with Apple
  Future<AuthUserModel> signInWithApple() async {
    try {
      // Request Apple sign in
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const core_exceptions.AuthException('No ID token from Apple');
      }

      // Sign in to Supabase with Apple ID token
      final response = await _supabase.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.apple,
        idToken: idToken,
      );

      if (response.user == null) {
        throw const core_exceptions.AuthException('Apple sign in failed: No user returned');
      }

      return AuthUserModel.fromSupabaseUser(response.user!);
    } on supabase.AuthException catch (e) {
      throw core_exceptions.AuthException(e.message);
    } catch (e) {
      throw core_exceptions.ServerException(e.toString());
    }
  }

  /// Sign out the current user
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      // Also sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } on supabase.AuthException catch (e) {
      throw core_exceptions.AuthException(e.message);
    } catch (e) {
      throw core_exceptions.ServerException(e.toString());
    }
  }

  /// Get the currently authenticated user
  Future<AuthUserModel?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;
      return AuthUserModel.fromSupabaseUser(user);
    } catch (e) {
      throw core_exceptions.ServerException(e.toString());
    }
  }

  /// Watch authentication state changes
  Stream<AuthUserModel?> watchAuthState() {
    return _supabase.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) return null;
      return AuthUserModel.fromSupabaseUser(user);
    });
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on supabase.AuthException catch (e) {
      throw core_exceptions.AuthException(e.message);
    } catch (e) {
      throw core_exceptions.ServerException(e.toString());
    }
  }
}

// Made with Bob
