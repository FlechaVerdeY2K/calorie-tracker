import 'package:calorie_tracker/core/secure_storage/secure_storage_service.dart';
import 'package:calorie_tracker/core/supabase/supabase_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorageService extends Mock implements SecureStorageService {}

void main() {
  group('SupabaseClientService', () {
    late MockSecureStorageService mockSecureStorage;

    setUp(() {
      mockSecureStorage = MockSecureStorageService();
    });

    test('isInitialized returns false before initialization', () {
      expect(SupabaseClientService.isInitialized, false);
    });

    test('client throws exception when not initialized', () {
      expect(
        () => SupabaseClientService.client,
        throwsA(isA<Exception>()),
      );
    });
  });

  group('SecureLocalStorage', () {
    late MockSecureStorageService mockSecureStorage;
    late SecureLocalStorage secureLocalStorage;

    setUp(() {
      mockSecureStorage = MockSecureStorageService();
      secureLocalStorage = SecureLocalStorage(mockSecureStorage);
    });

    test('initialize completes without error', () async {
      await expectLater(
        secureLocalStorage.initialize(),
        completes,
      );
    });

    test('accessToken reads from secure storage', () async {
      const testToken = 'test-access-token';
      when(() => mockSecureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => testToken);

      final result = await secureLocalStorage.accessToken();

      expect(result, testToken);
      verify(() => mockSecureStorage.read(key: 'supabase.auth.token'))
          .called(1);
    });

    test('hasAccessToken checks secure storage', () async {
      when(() => mockSecureStorage.containsKey(key: any(named: 'key')))
          .thenAnswer((_) async => true);

      final result = await secureLocalStorage.hasAccessToken();

      expect(result, true);
      verify(() => mockSecureStorage.containsKey(key: 'supabase.auth.token'))
          .called(1);
    });

    test('persistSession writes to secure storage', () async {
      const testSession = 'test-session-string';
      when(() => mockSecureStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) async => {});

      await secureLocalStorage.persistSession(testSession);

      verify(() => mockSecureStorage.write(
            key: 'supabase.auth.session',
            value: testSession,
          )).called(1);
    });

    test('removePersistedSession deletes both keys', () async {
      when(() => mockSecureStorage.delete(key: any(named: 'key')))
          .thenAnswer((_) async => {});

      await secureLocalStorage.removePersistedSession();

      verify(() => mockSecureStorage.delete(key: 'supabase.auth.session'))
          .called(1);
      verify(() => mockSecureStorage.delete(key: 'supabase.auth.token'))
          .called(1);
    });

    test('retrieveSession reads from secure storage', () async {
      const testSession = 'test-session-string';
      when(() => mockSecureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => testSession);

      final result = await secureLocalStorage.retrieveSession();

      expect(result, testSession);
      verify(() => mockSecureStorage.read(key: 'supabase.auth.session'))
          .called(1);
    });
  });
}

// Made with Bob
