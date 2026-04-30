import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:calorie_tracker/core/error/failures.dart';
import 'package:calorie_tracker/features/auth/domain/entities/auth_user.dart';
import 'package:calorie_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:calorie_tracker/features/auth/domain/usecases/sign_in_with_email.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignInWithEmail usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignInWithEmail(mockAuthRepository);
  });

  const tEmail = 'test@example.com';
  const tPassword = 'password123';
  final tAuthUser = AuthUser(
    id: '123',
    email: tEmail,
    displayName: 'Test User',
    photoUrl: null,
    createdAt: DateTime(2024, 1, 1),
    lastSignInAt: DateTime(2024, 1, 1),
    emailVerified: true,
  );

  test('should sign in user with email and password from repository', () async {
    // arrange
    when(() => mockAuthRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => Right(tAuthUser));

    // act
    final result = await usecase(
      const SignInWithEmailParams(email: tEmail, password: tPassword),
    );

    // assert
    expect(result, Right(tAuthUser));
    verify(() => mockAuthRepository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return AuthFailure when sign in fails', () async {
    // arrange
    const tFailure = AuthFailure('Invalid credentials');
    when(() => mockAuthRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(
      const SignInWithEmailParams(email: tEmail, password: tPassword),
    );

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return NetworkFailure when there is no internet connection',
      () async {
    // arrange
    const tFailure = NetworkFailure('No internet connection');
    when(() => mockAuthRepository.signInWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(
      const SignInWithEmailParams(email: tEmail, password: tPassword),
    );

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).called(1);
  });
}

// Made with Bob
