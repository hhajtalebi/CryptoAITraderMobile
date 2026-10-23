import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// No credentials in preferences, SQLite, source, crash reports or logs.
class SecureVault {
  final FlutterSecureStorage storage;
  const SecureVault({
    this.storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  });
  Future<void> save(String provider, String key, String secret) async {
    await storage.write(key: '$provider.key', value: key);
    await storage.write(key: '$provider.secret', value: secret);
  }

  Future<String?> read(String provider, String field) =>
      storage.read(key: '$provider.$field');
  Future<void> clear(String provider) async {
    await storage.delete(key: '$provider.key');
    await storage.delete(key: '$provider.secret');
  }
}
