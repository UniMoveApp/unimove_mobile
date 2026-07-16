import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/auth_service.dart';
import '../../auth/presentation/auth_controller.dart';
import 'notification_model.dart';

final notificationsProvider =
    StateNotifierProvider<NotificationsController, AsyncValue<List<NotificationModel>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authService = ref.watch(authServiceProvider);
  return NotificationsController(apiClient, authService, ref);
});

class NotificationsController extends StateNotifier<AsyncValue<List<NotificationModel>>> {
  final ApiClient _apiClient;
  final AuthService _authService;
  final Ref _ref;

  HttpClient? _sseClient;
  HttpClientRequest? _sseRequest;
  StreamSubscription? _sseSubscription;
  bool _isConnecting = false;

  NotificationsController(this._apiClient, this._authService, this._ref)
      : super(const AsyncValue.loading()) {
    // Carica le notifiche all'inizializzazione
    _init();
  }

  Future<void> _init() async {
    final authState = _ref.read(authControllerProvider);
    if (authState.status == AuthStatus.authenticated) {
      await fetchNotifications();
      // Avvia la connessione SSE in background
      _connectSse();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await _apiClient.dio.get('notifications');
      if (response.statusCode == 200 && response.data != null) {
        final rawList = response.data as List<dynamic>;
        final notifications = rawList
            .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
            .toList();
        state = AsyncValue.data(notifications);
      } else {
        state = AsyncValue.error('Impossibile caricare le notifiche', StackTrace.current);
      }
    } on DioException catch (e) {
      state = AsyncValue.error(
        e.response?.data?['message'] ?? e.message ?? 'Errore di rete',
        StackTrace.current,
      );
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }

  Future<void> markAsRead(String id) async {
    final currentList = state.value ?? [];
    try {
      // Ottimisticamente aggiorna lo stato in locale
      state = AsyncValue.data(
        currentList.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
      );

      final response = await _apiClient.dio.patch('notifications/$id/read');
      if (response.statusCode != 200) {
        throw Exception('Errore nel segnare la notifica come letta');
      }
    } catch (e) {
      // Rollback se fallisce
      state = AsyncValue.data(currentList);
      debugPrint('Errore markAsRead: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final currentList = state.value ?? [];
    try {
      state = AsyncValue.data(
        currentList.map((n) => n.copyWith(isRead: true)).toList(),
      );

      final response = await _apiClient.dio.patch('notifications/read-all');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Errore nel segnare tutte le notifiche come lette');
      }
    } catch (e) {
      state = AsyncValue.data(currentList);
      debugPrint('Errore markAllAsRead: $e');
    }
  }

  Future<void> deleteNotification(String id) async {
    final currentList = state.value ?? [];
    try {
      state = AsyncValue.data(
        currentList.where((n) => n.id != id).toList(),
      );

      final response = await _apiClient.dio.delete('notifications/$id');
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Errore durante l\'eliminazione della notifica');
      }
    } catch (e) {
      state = AsyncValue.data(currentList);
      debugPrint('Errore deleteNotification: $e');
    }
  }

  void _connectSse() async {
    if (_isConnecting) return;
    _isConnecting = true;

    int backoff = 1;

    while (mounted && _ref.read(authControllerProvider).status == AuthStatus.authenticated) {
      try {
        final token = await _authService.getToken();
        if (!mounted) return;
        if (token == null) {
          await Future.delayed(const Duration(seconds: 5));
          continue;
        }

        _sseClient = HttpClient();
        _sseClient!.connectionTimeout = const Duration(seconds: 15);

        // Costruisci l'URL corretto (es: http://10.66.192.119:8080/api/notifications/subscribe)
        final url = Uri.parse('${ApiConstants.baseUrl}notifications/subscribe');
        debugPrint('Connessione SSE in corso a: $url');
        
        _sseRequest = await _sseClient!.getUrl(url);
        _sseRequest!.headers.set('Authorization', 'Bearer $token');
        _sseRequest!.headers.set('Accept', 'text/event-stream');
        _sseRequest!.headers.set('Cache-Control', 'no-cache');

        if (!mounted) {
          _cleanupSse();
          return;
        }

        final response = await _sseRequest!.close();
        if (!mounted) {
          _cleanupSse();
          return;
        }

        if (response.statusCode != 200) {
          throw HttpException('Errore SSE: ${response.statusCode}');
        }

        debugPrint('Connessione SSE stabilita con successo.');
        backoff = 1; // reset backoff

        _sseSubscription = response
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
          debugPrint('SSE RICEVUTO: $line');
          if (!mounted) return;
          if (line.startsWith('data:')) {
            final dataStr = line.substring(5).trim();
            if (dataStr.isNotEmpty && dataStr != 'Connected') {
              try {
                final json = jsonDecode(dataStr) as Map<String, dynamic>;
                final notification = NotificationModel.fromJson(json);

                // Aggiungi la nuova notifica in cima alla lista se non è già presente
                final currentList = state.value ?? [];
                if (!currentList.any((n) => n.id == notification.id)) {
                  state = AsyncValue.data([notification, ...currentList]);
                  if (notification.type == 'NEW_REVIEW') {
                    _ref.invalidate(userProfileProvider);
                  }
                }
              } catch (e) {
                debugPrint('Errore parsing notifica SSE: $e');
              }
            }
          }
        }, onError: (e) {
          debugPrint('Errore nello stream SSE: $e');
          _cleanupSse();
        }, onDone: () {
          debugPrint('Stream SSE completato/chiuso dal server.');
          _cleanupSse();
        });

        // Rimaniamo in attesa finché la sottoscrizione è attiva
        while (mounted && _sseSubscription != null) {
          await Future.delayed(const Duration(seconds: 1));
        }
      } catch (e) {
        debugPrint('Connessione SSE persa: $e. Riconnessione in $backoff secondi...');
        _cleanupSse();
        if (!mounted) return;
        await Future.delayed(Duration(seconds: backoff));
        backoff = (backoff * 2).clamp(1, 60);
      }
    }
    _isConnecting = false;
  }

  void _cleanupSse() {
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _sseRequest?.abort();
    _sseRequest = null;
    _sseClient?.close(force: true);
    _sseClient = null;
  }

  @override
  void dispose() {
    _cleanupSse();
    super.dispose();
  }
}
