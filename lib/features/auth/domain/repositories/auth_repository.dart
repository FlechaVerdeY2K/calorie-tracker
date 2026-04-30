import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_user.dart';

/// Abstract repository interface for authentication operations.
/// Defines the contract that the data layer must implement.
abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, AuthUser>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, AuthUser>> signUpWithEmail({
    required String email,
    required String password,
  });

  /// Sign in with Google
  Future<Either<Failure, AuthUser>> signInWithGoogle();

  /// Sign in with Apple
  Future<Either<Failure, AuthUser>> signInWithApple();

  /// Sign out the current user
  Future<Either<Failure, void>> signOut();

  /// Get the currently authenticated user
  Future<Either<Failure, AuthUser?>> getCurrentUser();

  /// Watch authentication state changes
  /// Returns a stream that emits whenever the auth state changes
  Stream<Either<Failure, AuthUser?>> watchAuthState();

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  });
}

// Made with Bob
