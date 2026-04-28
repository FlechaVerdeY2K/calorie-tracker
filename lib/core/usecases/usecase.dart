import 'package:dartz/dartz.dart';
import '../error/failures.dart';

abstract class UseCase<Output, Params> {
  Future<Either<Failure, Output>> call(Params params);
}

abstract class StreamUseCase<Output, Params> {
  Stream<Either<Failure, Output>> call(Params params);
}
