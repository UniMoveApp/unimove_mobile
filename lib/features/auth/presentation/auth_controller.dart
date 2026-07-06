import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';

import '../domain/user_profile.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../rides/presentation/my_rides_controller.dart';
import '../../rides/presentation/my_bookings_controller.dart';
import '../../home/presentation/home_screen.dart';

/// Stato dell'autenticazione
enum AuthStatus { authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final bool isNewLogin;
  /// true se l'utente ha già completato il flusso di benvenuto su questo dispositivo
  final bool isOnboardingCompleted;

  AuthState({
    required this.status,
    this.errorMessage,
    this.isNewLogin = false,
    this.isOnboardingCompleted = false,
  });

  factory AuthState.authenticated({
    bool isNewLogin = false,
    bool isOnboardingCompleted = false,
  }) => AuthState(
    status: AuthStatus.authenticated,
    isNewLogin: isNewLogin,
    isOnboardingCompleted: isOnboardingCompleted,
  );
  factory AuthState.unauthenticated({String? error}) =>
      AuthState(status: AuthStatus.unauthenticated, errorMessage: error);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    bool? isNewLogin,
    bool? isOnboardingCompleted,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      isNewLogin: isNewLogin ?? this.isNewLogin,
      isOnboardingCompleted: isOnboardingCompleted ?? this.isOnboardingCompleted,
    );
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authService = ref.watch(authServiceProvider);
  return AuthController(apiClient, authService, ref);
});

class AuthController extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final AuthService _authService;
  final Ref _ref;

  AuthController(this._apiClient, this._authService, this._ref) : super(AuthState.loading()) {
    _init();
  }

  Future<void> _init() async {
    final isAuthenticated = await _authService.isAuthenticated();
    if (isAuthenticated) {
      final completed = await _authService.isOnboardingCompleted();
      state = AuthState.authenticated(isOnboardingCompleted: completed);
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login(String username, String password) async {
    state = AuthState.loading();
    try {
      final response = await _apiClient.dio.post(
        'auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final token = response.data['token'];
        if (token != null) {
          await _authService.saveToken(token);
          final completed = await _authService.isOnboardingCompleted();
          state = AuthState.authenticated(isNewLogin: true, isOnboardingCompleted: completed);
          return true;
        }
      }
      state = AuthState.unauthenticated(error: 'Errore durante il login');
      return false;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Credenziali errate o errore di rete';
      state = AuthState.unauthenticated(error: message);
      return false;
    } catch (e) {
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
          final completed = await _authService.isOnboardingCompleted();
          state = AuthState.authenticated(isNewLogin: true, isOnboardingCompleted: completed);
          return true;
        }
      }
      state = AuthState.unauthenticated(error: 'Errore durante la registrazione');
      return false;
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? 'Errore di rete o utente già esistente';
      state = AuthState.unauthenticated(error: message);
      return false;
    } catch (e) {
      state = AuthState.unauthenticated(error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.deleteToken();
    // Imposta PRIMA lo stato unauthenticated: il router fa redirect verso /login
    // e smette di watchare tutti i provider della home. Solo poi li invalidiamo
    // per evitare che si ricostruiscano con token null (→ 401 DioException).
    state = AuthState.unauthenticated();
    _ref.invalidate(profileControllerProvider);
    _ref.invalidate(myRidesProvider);
    _ref.invalidate(myBookingsProvider);
    _ref.invalidate(archivedRidesProvider);
  }

  Future<void> completeWelcome() async {
    await _authService.setOnboardingCompleted();
    state = state.copyWith(isNewLogin: false, isOnboardingCompleted: true);
  }
}

final userProfileProvider = FutureProvider<UserProfile?>((ref) {
  final authState = ref.watch(authControllerProvider);
  if (authState.status != AuthStatus.authenticated) {
    return Future.value(null);
  }
  // profileControllerProvider è un StateNotifier con stato AsyncValue<UserProfile?>
  // .when() converte l'AsyncValue in un Future: in loading triggera fetchProfile(),
  // in data/error ritorna il valore già disponibile — nessuna chiamata duplicata.
  final profileState = ref.watch(profileControllerProvider);
  final notifier = ref.read(profileControllerProvider.notifier);
  return profileState.when(
    data: (profile) => Future.value(profile),
    error: Future.error,
    loading: () => notifier.fetchProfile(),
  );
});

final userNameProvider = FutureProvider<String?>((ref) async {
  final profile = await ref.watch(userProfileProvider.future);
  if (profile == null) return null;
  final fullName = profile.fullName;
  if (fullName.trim().isEmpty) return null;
  return fullName.trim().split(' ').first;
});
