import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_user.freezed.dart';

/// Domain entity representing an authenticated user.
/// This is the pure domain representation, independent of any data source.
@freezed
class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String id,
    required String email,
    String? displayName,
    String? photoUrl,
    required DateTime createdAt,
    DateTime? lastSignInAt,
    required bool emailVerified,
  }) = _AuthUser;

  const AuthUser._();

  /// Check if user has a display name
  bool get hasDisplayName => displayName != null && displayName!.isNotEmpty;

  /// Check if user has a photo
  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  /// Get display name or fallback to email
  String get displayNameOrEmail => displayName ?? email;
}

// Made with Bob
