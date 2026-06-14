import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';

/// Stato dell'autenticazione
enum AuthStatus { authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;

  AuthState({required this.status, this.errorMessage});

  factory AuthState.authenticated() => AuthState(status: AuthStatus.authenticated);
  factory AuthState.unauthenticated({String? error}) => 
      AuthState(status: AuthStatus.unauthenticated, errorMessage: error);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.read(apiClientProvider),
    ref.read(authServiceProvider),
  );
});

class AuthController extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final AuthService _authService;

  AuthController(this._apiClient, this._authService) : super(AuthState.loading()) {
    _init();
  }

  Future<void> _init() async {
    final isAuthenticated = await _authService.isAuthenticated();
    state = isAuthenticated ? AuthState.authenticated() : AuthState.unauthenticated();
  }

  Future<bool> login(String username, String password) async {
    print("[DEBUG LOGIN] AuthController.login avviato per l'utente: $username");
    state = AuthState.loading();
    try {
      print("[DEBUG LOGIN] Chiamata POST su 'auth/login' in corso...");
      final response = await _apiClient.dio.post(
        'auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      print("[DEBUG LOGIN] Risposta ricevuta con status: ${response.statusCode}");
      if (response.statusCode == 200) {
        final token = response.data['token'];
        if (token != null) {
          print("[DEBUG LOGIN] Token ricevuto: $token. Salvo in Secure Storage...");
          await _authService.saveToken(token);
          state = AuthState.authenticated();
          print("[DEBUG LOGIN] Stato aggiornato a: AUTHENTICATED");
          return true;
        }
      }
      print("[DEBUG LOGIN] Login fallito (status non 200 o token nullo)");
      state = AuthState.unauthenticated(error: 'Errore durante il login');
      return false;
    } on DioException catch (e) {
      print("[DEBUG LOGIN] DioException catturata nel controller: ${e.message}");
      if (e.response != null) {
        print("[DEBUG LOGIN] Dati errore response: ${e.response?.data}");
      }
      final message = e.response?.data?['message'] ?? 'Credenziali errate o errore di rete';
      state = AuthState.unauthenticated(error: message);
      return false;
    } catch (e) {
      print("[DEBUG LOGIN] Errore generico catturato nel controller: $e");
      state = AuthState.unauthenticated(error: e.toString());
      return false;
    }
  }

  Future<bool> register(String username, String password, String fullName) async {
    state = AuthState.loading();
    try {
      final response = await _apiClient.dio.post(
        'auth/register',
        data: {
          'username': username,
          'password': password,
          'fullName': fullName,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        if (token != null) {
          await _authService.saveToken(token);
          state = AuthState.authenticated();
          return true;
        }
      }
      state = AuthState.unauthenticated(error: 'Errore durante la registrazione');
      return false;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? 'Errore di rete o utente già esistente';
      state = AuthState.unauthenticated(error: message);
      return false;
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.deleteToken();
    state = AuthState.unauthenticated();
  }
}
