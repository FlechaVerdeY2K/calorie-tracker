import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:calorie_tracker/core/error/failures.dart';
import 'package:calorie_tracker/core/usecases/no_params.dart';
import 'package:calorie_tracker/features/auth/domain/entities/auth_user.dart';
import 'package:calorie_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:calorie_tracker/features/auth/domain/usecases/watch_auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late WatchAuthState usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = WatchAuthState(mockAuthRepository);
  });

  final tAuthUser = AuthUser(
    id: '123',
    email: 'test@example.com',
    displayName: 'Test User',
    photoUrl: null,
    createdAt: DateTime(2024, 1, 1),
    lastSignInAt: DateTime(2024, 1, 1),
    emailVerified: true,
  );

  test('should emit auth state changes from repository', () async {
    // arrange
    final authStateStream = Stream<Either<Failure, AuthUser?>>.fromIterable([
      Right(tAuthUser),
      const Right(null),
      Right(tAuthUser),
    ]);

    when(() => mockAuthRepository.watchAuthState())
        .thenAnswer((_) => authStateStream);

    // act
    final result = usecase(NoParams());

    // assert
    expect(
      result,
      emitsInOrder([
        Right(tAuthUser),
        const Right(null),
        Right(tAuthUser),
      ]),
    );
    verify(() => mockAuthRepository.watchAuthState()).called(1);
  });

  test('should emit authenticated state when user signs in', () async {
    // arrange
    final authStateStream = Stream<Either<Failure, AuthUser?>>.fromIterable([
      const Right(null),
      Right(tAuthUser),
    ]);

    when(() => mockAuthRepository.watchAuthState())
        .thenAnswer((_) => authStateStream);

    // act
    final result = usecase(NoParams());

    // assert
    expect(
      result,
      emitsInOrder([
        const Right(null),
        Right(tAuthUser),
      ]),
    );
    verify(() => mockAuthRepository.watchAuthState()).called(1);
  });

  test('should emit unauthenticated state when user signs out', () async {
    // arrange
    final authStateStream = Stream<Either<Failure, AuthUser?>>.fromIterable([
      Right(tAuthUser),
      const Right(null),
    ]);

    when(() => mockAuthRepository.watchAuthState())
        .thenAnswer((_) => authStateStream);

    // act
    final result = usecase(NoParams());

    // assert
    expect(
      result,
      emitsInOrder([
        Right(tAuthUser),
        const Right(null),
      ]),
    );
    verify(() => mockAuthRepository.watchAuthState()).called(1);
  });

  test('should emit failure when auth state watching fails', () async {
    // arrange
    const tFailure = ServerFailure('Failed to watch auth state');
    final authStateStream = Stream<Either<Failure, AuthUser?>>.fromIterable([
      const Left(tFailure),
    ]);

    when(() => mockAuthRepository.watchAuthState())
        .thenAnswer((_) => authStateStream);

    // act
    final result = usecase(NoParams());

    // assert
    expect(
      result,
      emitsInOrder([
        const Left(tFailure),
      ]),
    );
    verify(() => mockAuthRepository.watchAuthState()).called(1);
  });

  test('should handle multiple subscribers to auth state stream', () async {
    // arrange
    final authStateStream = Stream<Either<Failure, AuthUser?>>.fromIterable([
      Right(tAuthUser),
      const Right(null),
    ]);

    when(() => mockAuthRepository.watchAuthState())
        .thenAnswer((_) => authStateStream);

    // act
    final result1 = usecase(NoParams());
    final result2 = usecase(NoParams());

    // assert
    expect(
      result1,
      emitsInOrder([
        Right(tAuthUser),
        const Right(null),
      ]),
    );
    expect(
      result2,
      emitsInOrder([
        Right(tAuthUser),
        const Right(null),
      ]),
    );
    verify(() => mockAuthRepository.watchAuthState()).called(2);
  });
}

// Made with Bob
