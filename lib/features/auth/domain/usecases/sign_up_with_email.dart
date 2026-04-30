import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Parameters for signing up with email and password
class SignUpWithEmailParams {
  final String email;
  final String password;

  const SignUpWithEmailParams({
    required this.email,
    required this.password,
  });
}

/// Use case for signing up with email and password
@injectable
class SignUpWithEmail implements UseCase<AuthUser, SignUpWithEmailParams> {
  final AuthRepository repository;

  SignUpWithEmail(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(SignUpWithEmailParams params) async {
    return await repository.signUpWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}

// Made with Bob
