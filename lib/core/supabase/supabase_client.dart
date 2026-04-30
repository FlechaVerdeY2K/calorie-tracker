import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../secure_storage/secure_storage_service.dart';

/// Singleton wrapper around Supabase client initialization.
/// Handles secure storage integration for auth token persistence.
class SupabaseClientService {
  static SupabaseClient? _client;
  static bool _initialized = false;

  /// Initialize Supabase with secure storage for auth persistence.
  /// Must be called before accessing [client].
  static Future<void> initialize({
    required SecureStorageService secureStorage,
  }) async {
    if (_initialized) {
      if (kDebugMode) {
        print('Supabase already initialized');
      }
      return;
    }

    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL not found in .env file');
    }

    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY not found in .env file');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: SecureLocalStorage(secureStorage),
      ),
      debug: kDebugMode,
    );

    _client = Supabase.instance.client;
    _initialized = true;

    if (kDebugMode) {
      print('Supabase initialized successfully');
      print('URL: $supabaseUrl');
    }
  }

  /// Get the Supabase client instance.
  /// Throws if [initialize] has not been called.
  static SupabaseClient get client {
    if (!_initialized || _client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseClientService.initialize() first.',
      );
    }
    return _client!;
  }

  /// Check if Supabase has been initialized
  static bool get isInitialized => _initialized;
}

/// Custom LocalStorage implementation using flutter_secure_storage
/// for secure auth token persistence on iOS Keychain and Android Keystore.
class SecureLocalStorage extends LocalStorage {
  final SecureStorageService _secureStorage;

  SecureLocalStorage(this._secureStorage);

  @override
  Future<void> initialize() async {
    // No initialization needed for flutter_secure_storage
  }

  @override
  Future<String?> accessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  @override
  Future<bool> hasAccessToken() async {
    return await _secureStorage.containsKey(key: _accessTokenKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _secureStorage.write(
      key: _persistSessionKey,
      value: persistSessionString,
    );
  }

  @override
  Future<void> removePersistedSession() async {
    await _secureStorage.delete(key: _persistSessionKey);
    await _secureStorage.delete(key: _accessTokenKey);
  }

  Future<String?> retrieveSession() async {
    return await _secureStorage.read(key: _persistSessionKey);
  }

  // Storage keys
  static const String _accessTokenKey = 'supabase.auth.token';
  static const String _persistSessionKey = 'supabase.auth.session';
}

// Made with Bob
