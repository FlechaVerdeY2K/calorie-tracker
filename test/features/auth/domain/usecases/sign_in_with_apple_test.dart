import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:calorie_tracker/core/error/failures.dart';
import 'package:calorie_tracker/core/usecases/no_params.dart';
import 'package:calorie_tracker/features/auth/domain/entities/auth_user.dart';
import 'package:calorie_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:calorie_tracker/features/auth/domain/usecases/sign_in_with_apple.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInWithApple usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignInWithApple(mockAuthRepository);
  });

  final tAuthUser = AuthUser(
    id: '101',
    email: 'apple@example.com',
    displayName: 'Apple User',
    photoUrl: null,
    createdAt: DateTime(2024, 1, 1),
    lastSignInAt: DateTime(2024, 1, 1),
    emailVerified: true,
  );

  test('should sign in user with Apple from repository', () async {
    // arrange
    when(() => mockAuthRepository.signInWithApple())
        .thenAnswer((_) async => Right(tAuthUser));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, Right(tAuthUser));
    verify(() => mockAuthRepository.signInWithApple()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return AuthFailure when Apple sign in is cancelled', () async {
    // arrange
    const tFailure = AuthFailure('Apple sign in cancelled');
    when(() => mockAuthRepository.signInWithApple())
        .thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.signInWithApple()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return ServerFailure when Apple sign in fails', () async {
    // arrange
    const tFailure = ServerFailure('Apple sign in failed');
    when(() => mockAuthRepository.signInWithApple())
        .thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.signInWithApple()).called(1);
  });

  test('should return NetworkFailure when there is no internet connection',
      () async {
    // arrange
    const tFailure = NetworkFailure('No internet connection');
    when(() => mockAuthRepository.signInWithApple())
        .thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.signInWithApple()).called(1);
  });
}

// Made with Bob
