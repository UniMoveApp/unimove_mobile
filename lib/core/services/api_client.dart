import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_service.dart';
import '../constants/api_constants.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final authService = ref.read(authServiceProvider);
  return ApiClient(authService);
});

class ApiClient {
  late final Dio _dio;
  final AuthService _authService;

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
        final token = await _authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) async {
        // Token scaduto → redirect al login
        if (e.response?.statusCode == 401) {
          await _authService.deleteToken();
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
}