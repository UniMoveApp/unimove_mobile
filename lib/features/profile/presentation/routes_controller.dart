import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_client.dart';

class RoutePreference {
  final String id;
  final String cityFrom;
  final String cityTo;

  RoutePreference({
    required this.id,
    required this.cityFrom,
    required this.cityTo,
  });

  factory RoutePreference.fromJson(Map<String, dynamic> json) {
    return RoutePreference(
      id: json['id'] as String? ?? '',
      cityFrom: json['cityFrom'] as String? ?? '',
      cityTo: json['cityTo'] as String? ?? '',
    );
  }
}

class RoutesController extends StateNotifier<AsyncValue<List<RoutePreference>>> {
  final ApiClient _apiClient;

  RoutesController(this._apiClient) : super(const AsyncValue.loading()) {
    fetchRoutes();
  }

  Future<void> fetchRoutes() async {
    state = const AsyncValue.loading();
    try {
      final response = await _apiClient.dio.get('users/me/routes');
      if (response.statusCode == 200 && response.data != null) {
        final list = (response.data as List<dynamic>)
            .map((e) => RoutePreference.fromJson(e as Map<String, dynamic>))
            .toList();
        state = AsyncValue.data(list);
      } else {
        throw Exception('Impossibile caricare le tratte preferite');
      }
    } catch (e, stack) {
      debugPrint('Errore nel recupero delle tratte preferite: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> addRoute(String cityFrom, String cityTo) async {
    final currentList = state.value ?? [];
    if (currentList.length >= 3) {
      return false;
    }

    try {
      final response = await _apiClient.dio.post(
        'users/me/routes',
        data: {
          'cityFrom': cityFrom,
          'cityTo': cityTo,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final newRoute = RoutePreference.fromJson(response.data as Map<String, dynamic>);
        state = AsyncValue.data([...currentList, newRoute]);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Errore nell\'aggiunta della tratta preferita: $e');
      return false;
    }
  }

  Future<bool> deleteRoute(String id) async {
    final currentList = state.value ?? [];
    try {
      final response = await _apiClient.dio.delete('users/me/routes/$id');
      if (response.statusCode == 200 || response.statusCode == 204) {
        final newList = currentList.where((route) => route.id != id).toList();
        state = AsyncValue.data(newList);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Errore nell\'eliminazione della tratta preferita: $e');
      return false;
    }
  }
}

final routesControllerProvider =
    StateNotifierProvider<RoutesController, AsyncValue<List<RoutePreference>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RoutesController(apiClient);
});
