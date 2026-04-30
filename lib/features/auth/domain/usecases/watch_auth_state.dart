import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Use case for watching authentication state changes
/// Returns a stream that emits whenever the auth state changes
@injectable
class WatchAuthState {
  final AuthRepository repository;

  WatchAuthState(this.repository);

  /// Call the use case to get the auth state stream
  Stream<Either<Failure, AuthUser?>> call() {
    return repository.watchAuthState();
  }
}

// Made with Bob
