// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthUserModel {
  String get id;
  String get email;
  @JsonKey(name: 'user_metadata')
  Map<String, dynamic>? get userMetadata;
  @JsonKey(name: 'created_at')
  String get createdAt;
  @JsonKey(name: 'last_sign_in_at')
  String? get lastSignInAt;
  @JsonKey(name: 'email_confirmed_at')
  String? get emailConfirmedAt;

  /// Create a copy of AuthUserModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AuthUserModelCopyWith<AuthUserModel> get copyWith =>
      _$AuthUserModelCopyWithImpl<AuthUserModel>(
          this as AuthUserModel, _$identity);

  /// Serializes this AuthUserModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AuthUserModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            const DeepCollectionEquality()
                .equals(other.userMetadata, userMetadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastSignInAt, lastSignInAt) ||
                other.lastSignInAt == lastSignInAt) &&
            (identical(other.emailConfirmedAt, emailConfirmedAt) ||
                other.emailConfirmedAt == emailConfirmedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      email,
      const DeepCollectionEquality().hash(userMetadata),
      createdAt,
      lastSignInAt,
      emailConfirmedAt);

  @override
  String toString() {
    return 'AuthUserModel(id: $id, email: $email, userMetadata: $userMetadata, createdAt: $createdAt, lastSignInAt: $lastSignInAt, emailConfirmedAt: $emailConfirmedAt)';
  }
}

/// @nodoc
abstract mixin class $AuthUserModelCopyWith<$Res> {
  factory $AuthUserModelCopyWith(
          AuthUserModel value, $Res Function(AuthUserModel) _then) =
      _$AuthUserModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String email,
      @JsonKey(name: 'user_metadata') Map<String, dynamic>? userMetadata,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'last_sign_in_at') String? lastSignInAt,
      @JsonKey(name: 'email_confirmed_at') String? emailConfirmedAt});
}

/// @nodoc
class _$AuthUserModelCopyWithImpl<$Res>
    implements $AuthUserModelCopyWith<$Res> {
  _$AuthUserModelCopyWithImpl(this._self, this._then);

  final AuthUserModel _self;
  final $Res Function(AuthUserModel) _then;

  /// Create a copy of AuthUserModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? userMetadata = freezed,
    Object? createdAt = null,
    Object? lastSignInAt = freezed,
    Object? emailConfirmedAt = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      userMetadata: freezed == userMetadata
          ? _self.userMetadata
          : userMetadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      lastSignInAt: freezed == lastSignInAt
          ? _self.lastSignInAt
          : lastSignInAt // ignore: cast_nullable_to_non_nullable
              as String?,
      emailConfirmedAt: freezed == emailConfirmedAt
          ? _self.emailConfirmedAt
          : emailConfirmedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [AuthUserModel].
extension AuthUserModelPatterns on AuthUserModel {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_AuthUserModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AuthUserModel() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_AuthUserModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthUserModel():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_AuthUserModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthUserModel() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id,
            String email,
            @JsonKey(name: 'user_metadata') Map<String, dynamic>? userMetadata,
            @JsonKey(name: 'created_at') String createdAt,
            @JsonKey(name: 'last_sign_in_at') String? lastSignInAt,
            @JsonKey(name: 'email_confirmed_at') String? emailConfirmedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AuthUserModel() when $default != null:
        return $default(_that.id, _that.email, _that.userMetadata,
            _that.createdAt, _that.lastSignInAt, _that.emailConfirmedAt);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id,
            String email,
            @JsonKey(name: 'user_metadata') Map<String, dynamic>? userMetadata,
            @JsonKey(name: 'created_at') String createdAt,
            @JsonKey(name: 'last_sign_in_at') String? lastSignInAt,
            @JsonKey(name: 'email_confirmed_at') String? emailConfirmedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthUserModel():
        return $default(_that.id, _that.email, _that.userMetadata,
            _that.createdAt, _that.lastSignInAt, _that.emailConfirmedAt);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id,
            String email,
            @JsonKey(name: 'user_metadata') Map<String, dynamic>? userMetadata,
            @JsonKey(name: 'created_at') String createdAt,
            @JsonKey(name: 'last_sign_in_at') String? lastSignInAt,
            @JsonKey(name: 'email_confirmed_at') String? emailConfirmedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuthUserModel() when $default != null:
        return $default(_that.id, _that.email, _that.userMetadata,
            _that.createdAt, _that.lastSignInAt, _that.emailConfirmedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _AuthUserModel extends AuthUserModel {
  const _AuthUserModel(
      {required this.id,
      required this.email,
      @JsonKey(name: 'user_metadata') final Map<String, dynamic>? userMetadata,
      @JsonKey(name: 'created_at') required this.createdAt,
      @JsonKey(name: 'last_sign_in_at') this.lastSignInAt,
      @JsonKey(name: 'email_confirmed_at') this.emailConfirmedAt})
      : _userMetadata = userMetadata,
        super._();
  factory _AuthUserModel.fromJson(Map<String, dynamic> json) =>
      _$AuthUserModelFromJson(json);

  @override
  final String id;
  @override
  final String email;
  final Map<String, dynamic>? _userMetadata;
  @override
  @JsonKey(name: 'user_metadata')
  Map<String, dynamic>? get userMetadata {
    final value = _userMetadata;
    if (value == null) return null;
    if (_userMetadata is EqualUnmodifiableMapView) return _userMetadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @JsonKey(name: 'created_at')
  final String createdAt;
  @override
  @JsonKey(name: 'last_sign_in_at')
  final String? lastSignInAt;
  @override
  @JsonKey(name: 'email_confirmed_at')
  final String? emailConfirmedAt;

  /// Create a copy of AuthUserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AuthUserModelCopyWith<_AuthUserModel> get copyWith =>
      __$AuthUserModelCopyWithImpl<_AuthUserModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$AuthUserModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AuthUserModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            const DeepCollectionEquality()
                .equals(other._userMetadata, _userMetadata) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.lastSignInAt, lastSignInAt) ||
                other.lastSignInAt == lastSignInAt) &&
            (identical(other.emailConfirmedAt, emailConfirmedAt) ||
                other.emailConfirmedAt == emailConfirmedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      email,
      const DeepCollectionEquality().hash(_userMetadata),
      createdAt,
      lastSignInAt,
      emailConfirmedAt);

  @override
  String toString() {
    return 'AuthUserModel(id: $id, email: $email, userMetadata: $userMetadata, createdAt: $createdAt, lastSignInAt: $lastSignInAt, emailConfirmedAt: $emailConfirmedAt)';
  }
}

/// @nodoc
abstract mixin class _$AuthUserModelCopyWith<$Res>
    implements $AuthUserModelCopyWith<$Res> {
  factory _$AuthUserModelCopyWith(
          _AuthUserModel value, $Res Function(_AuthUserModel) _then) =
      __$AuthUserModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String email,
      @JsonKey(name: 'user_metadata') Map<String, dynamic>? userMetadata,
      @JsonKey(name: 'created_at') String createdAt,
      @JsonKey(name: 'last_sign_in_at') String? lastSignInAt,
      @JsonKey(name: 'email_confirmed_at') String? emailConfirmedAt});
}

/// @nodoc
class __$AuthUserModelCopyWithImpl<$Res>
    implements _$AuthUserModelCopyWith<$Res> {
  __$AuthUserModelCopyWithImpl(this._self, this._then);

  final _AuthUserModel _self;
  final $Res Function(_AuthUserModel) _then;

  /// Create a copy of AuthUserModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? userMetadata = freezed,
    Object? createdAt = null,
    Object? lastSignInAt = freezed,
    Object? emailConfirmedAt = freezed,
  }) {
    return _then(_AuthUserModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      userMetadata: freezed == userMetadata
          ? _self._userMetadata
          : userMetadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String,
      lastSignInAt: freezed == lastSignInAt
          ? _self.lastSignInAt
          : lastSignInAt // ignore: cast_nullable_to_non_nullable
              as String?,
      emailConfirmedAt: freezed == emailConfirmedAt
          ? _self.emailConfirmedAt
          : emailConfirmedAt // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
