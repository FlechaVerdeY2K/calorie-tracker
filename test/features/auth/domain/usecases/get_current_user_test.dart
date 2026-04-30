import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:calorie_tracker/core/error/failures.dart';
import 'package:calorie_tracker/core/usecases/no_params.dart';
import 'package:calorie_tracker/features/auth/domain/entities/auth_user.dart';
import 'package:calorie_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:calorie_tracker/features/auth/domain/usecases/get_current_user.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late GetCurrentUser usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = GetCurrentUser(mockAuthRepository);
  });

  final tAuthUser = AuthUser(
    id: '123',
    email: 'current@example.com',
    displayName: 'Current User',
    photoUrl: null,
    createdAt: DateTime(2024, 1, 1),
    lastSignInAt: DateTime(2024, 1, 1),
    emailVerified: true,
  );

  test('should get current user from repository when user is authenticated',
      () async {
    // arrange
    when(() => mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => Right(tAuthUser));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, Right(tAuthUser));
    verify(() => mockAuthRepository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return null when no user is authenticated', () async {
    // arrange
    when(() => mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Right(null));
    verify(() => mockAuthRepository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return AuthFailure when getting current user fails', () async {
    // arrange
    const tFailure = AuthFailure('Failed to get current user');
    when(() => mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.getCurrentUser()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return ServerFailure when there is a server error', () async {
    // arrange
    const tFailure = ServerFailure('Server error');
    when(() => mockAuthRepository.getCurrentUser())
        .thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.getCurrentUser()).called(1);
  });
}

// Made with Bob
