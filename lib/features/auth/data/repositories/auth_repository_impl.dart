import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of AuthRepository using Supabase
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, AuthUser>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _guard(() async {
      final model = await remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, AuthUser>> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _guard(() async {
      final model = await remoteDataSource.signUpWithEmail(
        email: email,
        password: password,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithGoogle() async {
    return await _guard(() async {
      final model = await remoteDataSource.signInWithGoogle();
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithApple() async {
    return await _guard(() async {
      final model = await remoteDataSource.signInWithApple();
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    return await _guard(() async {
      await remoteDataSource.signOut();
    });
  }

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() async {
    return await _guard(() async {
      final model = await remoteDataSource.getCurrentUser();
      return model?.toEntity();
    });
  }

  @override
  Stream<Either<Failure, AuthUser?>> watchAuthState() {
    try {
      return remoteDataSource.watchAuthState().map(
            (model) => Right<Failure, AuthUser?>(model?.toEntity()),
          );
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail({
    required String email,
  }) async {
    return await _guard(() async {
      await remoteDataSource.sendPasswordResetEmail(email: email);
    });
  }

  /// Guard pattern for error handling
  /// Catches exceptions and converts them to Failures
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on SocketException {
      return const Left(NetworkFailure('No internet connection'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}

// Made with Bob
