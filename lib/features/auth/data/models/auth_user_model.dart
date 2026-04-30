import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../domain/entities/auth_user.dart';

part 'auth_user_model.freezed.dart';
part 'auth_user_model.g.dart';

/// Data model for AuthUser with JSON serialization
@freezed
class AuthUserModel with _$AuthUserModel {
  const factory AuthUserModel({
    required String id,
    required String email,
    @JsonKey(name: 'user_metadata') Map<String, dynamic>? userMetadata,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'last_sign_in_at') String? lastSignInAt,
    @JsonKey(name: 'email_confirmed_at') String? emailConfirmedAt,
  }) = _AuthUserModel;

  const AuthUserModel._();

  factory AuthUserModel.fromJson(Map<String, dynamic> json) =>
      _$AuthUserModelFromJson(json);

  /// Convert from Supabase User to AuthUserModel
  factory AuthUserModel.fromSupabaseUser(supabase.User user) {
    return AuthUserModel(
      id: user.id,
      email: user.email ?? '',
      userMetadata: user.userMetadata,
      createdAt: user.createdAt,
      lastSignInAt: user.lastSignInAt,
      emailConfirmedAt: user.emailConfirmedAt,
    );
  }

  /// Convert to domain entity
  AuthUser toEntity() {
    return AuthUser(
      id: id,
      email: email,
      displayName: userMetadata?['full_name'] as String?,
      photoUrl: userMetadata?['avatar_url'] as String?,
      createdAt: DateTime.parse(createdAt),
      lastSignInAt:
          lastSignInAt != null ? DateTime.parse(lastSignInAt!) : null,
      emailVerified: emailConfirmedAt != null,
    );
  }

  /// Create from domain entity
  factory AuthUserModel.fromEntity(AuthUser entity) {
    return AuthUserModel(
      id: entity.id,
      email: entity.email,
      userMetadata: {
        if (entity.displayName != null) 'full_name': entity.displayName,
        if (entity.photoUrl != null) 'avatar_url': entity.photoUrl,
      },
      createdAt: entity.createdAt.toIso8601String(),
      lastSignInAt: entity.lastSignInAt?.toIso8601String(),
      emailConfirmedAt:
          entity.emailVerified ? entity.createdAt.toIso8601String() : null,
    );
  }
}

// Made with Bob
