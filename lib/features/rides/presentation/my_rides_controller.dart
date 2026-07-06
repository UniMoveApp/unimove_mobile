import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../core/services/api_client.dart';
import '../../auth/domain/user_profile.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../home/presentation/home_screen.dart';

// Il backend supporta ?status= su GET /rides/my
// Richiediamo separatamente OPEN e IN_PROGRESS per avere solo le corse attive
final myRidesProvider = FutureProvider<List<Ride>>((ref) async {
  // Guard: non effettuare chiamate API se l'utente non è autenticato
  final authState = ref.watch(authControllerProvider);
  if (authState.status != AuthStatus.authenticated) return [];

  final apiClient = ref.watch(apiClientProvider);
  final responses = await Future.wait([
    apiClient.dio.get('rides/my', queryParameters: {'status': 'OPEN'}),
    apiClient.dio.get('rides/my', queryParameters: {'status': 'IN_PROGRESS'}),
  ]);
  final List<Ride> result = [];
  for (final response in responses) {
    if (response.statusCode == 200 && response.data != null) {
      final list = response.data as List<dynamic>;
      result.addAll(list.map((e) => Ride.fromJson(e as Map<String, dynamic>)));
    }
  }
  // Ordina per orario di partenza
  result.sort((a, b) => a.departureTime.compareTo(b.departureTime));
  return result;
});

class MyRidesService {
  final ApiClient _apiClient;
  final Ref _ref;

  MyRidesService(this._apiClient, this._ref);

  Future<void> startRide(String rideId) async {
    try {
      final response = await _apiClient.dio.put('rides/$rideId/start');
      if (response.statusCode == 200) {
        _ref.invalidate(myRidesProvider);
        _ref.invalidate(userProfileProvider);
      } else {
        throw Exception('Errore durante l\'avvio della corsa');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Impossibile avviare la corsa';
      throw Exception(msg);
    }
  }

  Future<void> completeRide(String rideId) async {
    try {
      final response = await _apiClient.dio.put('rides/$rideId/complete');
      if (response.statusCode == 200) {
        _ref.invalidate(myRidesProvider);
        _ref.invalidate(userProfileProvider);
        _ref.invalidate(archivedRidesProvider);
      } else {
        throw Exception('Errore durante il completamento della corsa');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Impossibile completare la corsa';
      throw Exception(msg);
    }
  }

  Future<void> deleteRide(String rideId) async {
    try {
      final response = await _apiClient.dio.delete('rides/$rideId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        _ref.invalidate(myRidesProvider);
        _ref.invalidate(userProfileProvider);
      } else {
        throw Exception('Errore durante l\'eliminazione della corsa');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Impossibile eliminare la corsa';
      throw Exception(msg);
    }
  }
}

final myRidesServiceProvider = Provider<MyRidesService>((ref) {
  return MyRidesService(ref.watch(apiClientProvider), ref);
});
