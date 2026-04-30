// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:calorie_tracker/core/secure_storage/secure_storage_service.dart'
    as _i824;
import 'package:calorie_tracker/features/auth/data/datasources/auth_remote_datasource.dart'
    as _i694;
import 'package:calorie_tracker/features/auth/data/repositories/auth_repository_impl.dart'
    as _i739;
import 'package:calorie_tracker/features/auth/domain/repositories/auth_repository.dart'
    as _i566;
import 'package:calorie_tracker/features/auth/domain/usecases/get_current_user.dart'
    as _i867;
import 'package:calorie_tracker/features/auth/domain/usecases/sign_in_with_apple.dart'
    as _i621;
import 'package:calorie_tracker/features/auth/domain/usecases/sign_in_with_email.dart'
    as _i1012;
import 'package:calorie_tracker/features/auth/domain/usecases/sign_in_with_google.dart'
    as _i647;
import 'package:calorie_tracker/features/auth/domain/usecases/sign_out.dart'
    as _i374;
import 'package:calorie_tracker/features/auth/domain/usecases/sign_up_with_email.dart'
    as _i736;
import 'package:calorie_tracker/features/auth/domain/usecases/watch_auth_state.dart'
    as _i521;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.lazySingleton<_i824.SecureStorageService>(
        () => _i824.SecureStorageService());
    gh.lazySingleton<_i694.AuthRemoteDataSource>(
        () => _i694.AuthRemoteDataSource());
    gh.lazySingleton<_i566.AuthRepository>(
        () => _i739.AuthRepositoryImpl(gh<_i694.AuthRemoteDataSource>()));
    gh.factory<_i867.GetCurrentUser>(
        () => _i867.GetCurrentUser(gh<_i566.AuthRepository>()));
    gh.factory<_i621.SignInWithApple>(
        () => _i621.SignInWithApple(gh<_i566.AuthRepository>()));
    gh.factory<_i1012.SignInWithEmail>(
        () => _i1012.SignInWithEmail(gh<_i566.AuthRepository>()));
    gh.factory<_i647.SignInWithGoogle>(
        () => _i647.SignInWithGoogle(gh<_i566.AuthRepository>()));
    gh.factory<_i374.SignOut>(() => _i374.SignOut(gh<_i566.AuthRepository>()));
    gh.factory<_i736.SignUpWithEmail>(
        () => _i736.SignUpWithEmail(gh<_i566.AuthRepository>()));
    gh.factory<_i521.WatchAuthState>(
        () => _i521.WatchAuthState(gh<_i566.AuthRepository>()));
    return this;
  }
}
