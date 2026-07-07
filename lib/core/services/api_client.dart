import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import '../constants/api_constants.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final authService = ref.watch(authServiceProvider);
  return ApiClient(authService);
});

class ApiClient {
  late final Dio _dio;
  final AuthService _authService;

  /// Callback impostato da AuthController: viene chiamato quando il server
  /// risponde con 401 (sessione scaduta) in modo da aggiornare lo stato
  /// di autenticazione senza dipendenze circolari tra i provider.
  VoidCallback? onUnauthorized;

  ApiClient(this._authService) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ));

    // Interceptor: aggiunge JWT a ogni richiesta
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final token = await _authService.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        } catch (_) {}
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        final statusCode = e.response?.statusCode;

        if (statusCode == 401) {
          // Token scaduto o non valido: elimina il token e notifica l'AuthController
          await _authService.deleteToken();
          onUnauthorized?.call();
        }

        // Personalizza il messaggio di errore in base al tipo
        String errorMessage;
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage = 'Connessione al server scaduta. Riprova.';
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage = 'Impossibile connettersi al server. Verifica la tua connessione.';
        } else if (e.response == null) {
          errorMessage = 'Errore di rete. Controlla la tua connessione.';
        } else if (statusCode == 401) {
          errorMessage = 'Sessione scaduta. Effettua di nuovo il login.';
        } else if (statusCode == 403) {
          errorMessage = 'Accesso non autorizzato (403). Effettua di nuovo il login.';
        } else if (statusCode != null && statusCode >= 500) {
          errorMessage = 'Errore del server ($statusCode). Riprova pi\u00f9 tardi.';
        } else {
          // Per tutti gli altri errori HTTP, passa l'eccezione originale
          return handler.next(e);
        }

        return handler.next(DioException(
          requestOptions: e.requestOptions,
          response: e.response,
          type: e.type,
          error: e.error,
          message: errorMessage,
        ));
      },
    ));
  }

  Dio get dio => _dio;
}