import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Wrapper around flutter_secure_storage for secure token and sensitive data storage.
/// Uses iOS Keychain and Android Keystore for platform-native encryption.
@lazySingleton
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  /// Write a key-value pair to secure storage
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  /// Read a value from secure storage
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  /// Delete a key from secure storage
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  /// Delete all keys from secure storage
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Check if a key exists in secure storage
  Future<bool> containsKey({required String key}) async {
    return await _storage.containsKey(key: key);
  }

  /// Read all keys from secure storage
  Future<Map<String, String>> readAll() async {
    return await _storage.readAll();
  }
}

// Made with Bob
