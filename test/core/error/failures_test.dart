import 'package:calorie_tracker/core/error/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure equality', () {
    test('same type and message are equal', () {
      expect(const ServerFailure('oops'), equals(const ServerFailure('oops')));
    });

    test('different message not equal', () {
      expect(const ServerFailure('a'), isNot(equals(const ServerFailure('b'))));
    });

    test('different subtypes not equal', () {
      expect(const ServerFailure('x'), isNot(equals(const NetworkFailure('x'))));
    });

    test('all subtypes instantiate', () {
      const failures = [
        ServerFailure('s'),
        NetworkFailure('n'),
        AuthFailure('a'),
        ValidationFailure('v'),
        CacheFailure('c'),
        RateLimitFailure('r'),
      ];
      expect(failures.length, 6);
    });
  });
}
