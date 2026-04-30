// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AuthUserModel _$AuthUserModelFromJson(Map<String, dynamic> json) =>
    _AuthUserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      userMetadata: json['user_metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String,
      lastSignInAt: json['last_sign_in_at'] as String?,
      emailConfirmedAt: json['email_confirmed_at'] as String?,
    );

Map<String, dynamic> _$AuthUserModelToJson(_AuthUserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'user_metadata': instance.userMetadata,
      'created_at': instance.createdAt,
      'last_sign_in_at': instance.lastSignInAt,
      'email_confirmed_at': instance.emailConfirmedAt,
    };
