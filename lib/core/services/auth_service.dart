import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';

  /// Salva il token JWT
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Legge il token JWT
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Elimina il token (logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Controlla se l'utente è autenticato e il token non è scaduto
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;
    try {
      final jwt = JWT.decode(token); // decode senza verifica firma (solo exp check)
      final exp = jwt.payload['exp'];
      if (exp == null) return true;
      final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isBefore(expiry);
    } catch (_) {
      return false;
    }
  }
}