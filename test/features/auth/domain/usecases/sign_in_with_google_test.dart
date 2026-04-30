import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:calorie_tracker/core/error/failures.dart';
import 'package:calorie_tracker/core/usecases/no_params.dart';
import 'package:calorie_tracker/features/auth/domain/entities/auth_user.dart';
import 'package:calorie_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:calorie_tracker/features/auth/domain/usecases/sign_in_with_google.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInWithGoogle usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignInWithGoogle(mockAuthRepository);
  });

  final tAuthUser = AuthUser(
    id: '789',
    email: 'google@example.com',
    displayName: 'Google User',
    photoUrl: 'https://example.com/photo.jpg',
    createdAt: DateTime(2024, 1, 1),
    lastSignInAt: DateTime(2024, 1, 1),
    emailVerified: true,
  );

  test('should sign in user with Google from repository', () async {
    // arrange
    when(() => mockAuthRepository.signInWithGoogle())
        .thenAnswer((_) async => Right(tAuthUser));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, Right(tAuthUser));
    verify(() => mockAuthRepository.signInWithGoogle()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return AuthFailure when Google sign in is cancelled', () async {
    // arrange
    const tFailure = AuthFailure('Google sign in cancelled');
    when(() => mockAuthRepository.signInWithGoogle())
        .thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.signInWithGoogle()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return ServerFailure when Google sign in fails', () async {
    // arrange
    const tFailure = ServerFailure('Google sign in failed');
    when(() => mockAuthRepository.signInWithGoogle())
        .thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.signInWithGoogle()).called(1);
  });

  test('should return NetworkFailure when there is no internet connection',
      () async {
    // arrange
    const tFailure = NetworkFailure('No internet connection');
    when(() => mockAuthRepository.signInWithGoogle())
        .thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.signInWithGoogle()).called(1);
  });
}

// Made with Bob
