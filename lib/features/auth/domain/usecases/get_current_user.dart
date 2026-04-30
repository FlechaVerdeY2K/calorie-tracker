import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/no_params.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Use case for getting the currently authenticated user
@injectable
class GetCurrentUser implements UseCase<AuthUser?, NoParams> {
  final AuthRepository repository;

  GetCurrentUser(this.repository);

  @override
  Future<Either<Failure, AuthUser?>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}

// Made with Bob
