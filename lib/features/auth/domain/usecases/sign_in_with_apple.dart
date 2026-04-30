import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/no_params.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing in with Apple
@injectable
class SignInWithApple implements UseCase<AuthUser, NoParams> {
  final AuthRepository repository;

  SignInWithApple(this.repository);

  @override
  Future<Either<Failure, AuthUser>> call(NoParams params) async {
    return await repository.signInWithApple();
  }
}

// Made with Bob
