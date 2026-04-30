import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:calorie_tracker/core/error/failures.dart';
import 'package:calorie_tracker/features/auth/domain/entities/auth_user.dart';
import 'package:calorie_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:calorie_tracker/features/auth/domain/usecases/sign_up_with_email.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late SignUpWithEmail usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignUpWithEmail(mockAuthRepository);
  });

  const tEmail = 'newuser@example.com';
  const tPassword = 'password123';
  final tAuthUser = AuthUser(
    id: '456',
    email: tEmail,
    displayName: null,
    photoUrl: null,
    createdAt: DateTime(2024, 1, 1),
    lastSignInAt: null,
    emailVerified: false,
  );

  test('should sign up user with email and password from repository', () async {
    // arrange
    when(() => mockAuthRepository.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => Right(tAuthUser));

    // act
    final result = await usecase(
      const SignUpWithEmailParams(email: tEmail, password: tPassword),
    );

    // assert
    expect(result, Right(tAuthUser));
    verify(() => mockAuthRepository.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return AuthFailure when email is already in use', () async {
    // arrange
    const tFailure = AuthFailure('Email already in use');
    when(() => mockAuthRepository.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(
      const SignUpWithEmailParams(email: tEmail, password: tPassword),
    );

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).called(1);
    verifyNoMoreInteractions(mockAuthRepository);
  });

  test('should return ValidationFailure when password is too weak', () async {
    // arrange
    const tFailure = ValidationFailure('Password is too weak');
    when(() => mockAuthRepository.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(
      const SignUpWithEmailParams(email: tEmail, password: '123'),
    );

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.signUpWithEmail(
          email: tEmail,
          password: '123',
        )).called(1);
  });

  test('should return NetworkFailure when there is no internet connection',
      () async {
    // arrange
    const tFailure = NetworkFailure('No internet connection');
    when(() => mockAuthRepository.signUpWithEmail(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Left(tFailure));

    // act
    final result = await usecase(
      const SignUpWithEmailParams(email: tEmail, password: tPassword),
    );

    // assert
    expect(result, const Left(tFailure));
    verify(() => mockAuthRepository.signUpWithEmail(
          email: tEmail,
          password: tPassword,
        )).called(1);
  });
}

// Made with Bob
