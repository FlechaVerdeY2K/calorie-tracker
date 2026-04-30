import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:calorie_tracker/core/error/failures.dart';
import 'package:calorie_tracker/core/usecases/no_params.dart';
import 'package:calorie_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:calorie_tracker/features/auth/domain/usecases/sign_out.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignOut usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignOut(mockAuthRepository);
  });

  test('should sign out user from repository', () async {
    // arrange
    when(() => mockAuthRepository.signOut())
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Right(null));
    verify(() => mockAuthRepository.signOut()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return ServerFailure when sign out fails', () async {
    // arrange
    const tFailure = ServerFailure('Failed to sign out');
    when(() => mockAuthRepository.signOut())
        .thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.signOut()).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return NetworkFailure when there is no internet connection',
      () async {
    // arrange
    const tFailure = NetworkFailure('No internet connection');
    when(() => mockAuthRepository.signOut())
        .thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(NoParams());

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.signOut()).called(1);
  });
}

// Made with Bob
